pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Visibility state
    property bool visible: false

    // Clipboard data
    property list<QtObject> clipboardItems: []
    property int lastKnownCount: -1

    // Filtering and pagination
    property string filterText: ""
    property string filterType: "all" // all, text, multiline, image, html, url, non-text
    property int currentPage: 0

    // Constants
    readonly property int itemsPerPage: 15
    readonly property int previewLength: 100
    readonly property int maxConcurrency: 6

    Component.onCompleted: {
        console.log("[Clipboard] Service initialized; triggering initial load")
        refreshClipboard();
    }

    // Derived properties
    readonly property var filteredItems: {
        let result = clipboardItems;
        
        // Apply type filter
        if (filterType !== "all") {
            result = result.filter(item => {
                if (filterType === "text") {
                    return item.type === "text" || item.type === "multiline";
                }
                return item.type === filterType;
            });
        }
        
        // Apply text filter
        const f = filterText.trim().toLowerCase();
        if (f !== "") {
            result = result.filter(item => item.text.toLowerCase().includes(f));
        }
        
        return result;
    }

    readonly property var paginatedItems: {
        const startIndex = currentPage * itemsPerPage;
        const endIndex = startIndex + itemsPerPage;
        return filteredItems.slice(startIndex, endIndex);
    }

    readonly property int totalPages: Math.max(1, Math.ceil(filteredItems.length / itemsPerPage))

    // Functions
    function toggleVisible() {
        console.log("[Clipboard] toggleVisible called; before= " + visible);
        visible = !visible;
        console.log("[Clipboard] toggleVisible finished; after= " + visible);
    }

    function nextPage() {
        if (currentPage < totalPages - 1) {
            currentPage++;
        }
    }

    function previousPage() {
        if (currentPage > 0) {
            currentPage--;
        }
    }

    function resetFilters() {
        filterText = "";
        filterType = "all";
        currentPage = 0;
    }

    function selectItem(item) {
        selectProc.exec(["copyq", "select", item.index.toString()]);
        
        // Reorder locally
        const selectedOldIndex = item.index;
        const remapped = clipboardItems.map(it => {
            if (it.index === selectedOldIndex) {
                it.index = 0;
                return it;
            }
            if (it.index < selectedOldIndex) {
                it.index = it.index + 1;
                return it;
            }
            return it;
        });
        remapped.sort((a, b) => a.index - b.index);
        clipboardItems = remapped;
        
        visible = false;
        Qt.callLater(refreshClipboard);
    }

    function removeItem(item) {
        removeProc.exec(["copyq", "remove", item.index.toString()]);
        
        // Remove locally
        const removedIndex = item.index;
        const filtered = clipboardItems.filter(it => it.index !== removedIndex);
        const adjusted = filtered.map(it => {
            if (it.index > removedIndex) {
                it.index = it.index - 1;
            }
            return it;
        });
        adjusted.sort((a, b) => a.index - b.index);
        clipboardItems = adjusted;
        
        lastKnownCount = Math.max(0, lastKnownCount - 1);
        
        // Fix pagination
        if (currentPage > totalPages - 1) {
            currentPage = Math.max(0, totalPages - 1);
        }
    }

    function clearHistory() {
        clearProc.running = true;
    }

    function refreshClipboard() {
        console.log("[Clipboard] refreshClipboard invoked");
        smartRefreshProc.running = true;
    }

    // Decode escaped unicode sequences
    function decodeEscapedText(input) {
        try {
            let s = input;
            s = s.replace(/\\n/g, "\n").replace(/\\t/g, "\t");
            // Basic unicode escape handling (simplified)
            return s;
        } catch (e) {
            return input;
        }
    }

    // Auto-refresh timer when visible
    Timer {
        id: autoRefreshTimer
        running: root.visible
        interval: 2000
        repeat: true
        onTriggered: {
            console.log("[Clipboard] autoRefreshTimer tick; triggering smartRefresh");
            smartRefreshProc.running = true;
        }
    }

    // Smart refresh process
    Process {
        id: smartRefreshProc
        
        command: ["copyq", "count"]
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[Clipboard] smartRefreshProc finished; stdout=\n" + text)
                const currentCount = parseInt(text.trim());
                
                if (lastKnownCount < 0) {
                    lastKnownCount = currentCount;
                    if (clipboardItems.length === 0) {
                        fullRefreshProc.running = true;
                    }
                    return;
                }
                
                if (currentCount === lastKnownCount) {
                    return;
                }
                
                if (currentCount > lastKnownCount) {
                    // New items added - incremental fetch
                    const delta = currentCount - lastKnownCount;
                    fetchRangeProc.startIndex = 0;
                    fetchRangeProc.endIndex = delta;
                    fetchRangeProc.isIncremental = true;
                    console.log("[Clipboard] Detected new items; delta=" + delta + ", starting incremental fetch 0.." + delta);
                    fetchRangeProc.running = true;
                } else {
                    // Items removed - full refresh
                    console.log("[Clipboard] Detected removal; starting full refresh");
                    fullRefreshProc.running = true;
                }
            }
        }
    }

    // Full refresh process
    Process {
        id: fullRefreshProc
        
        command: ["copyq", "count"]
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[Clipboard] fullRefresh count stdout=\n" + text)
                const count = parseInt(text.trim());
                if (count === 0) {
                    console.log("[Clipboard] No items; clearing list");
                    clipboardItems = [];
                    lastKnownCount = 0;
                    return;
                }
                
                fetchRangeProc.startIndex = 0;
                fetchRangeProc.endIndex = count;
                fetchRangeProc.isIncremental = false;
                console.log("[Clipboard] Starting full fetch 0.." + count);
                fetchRangeProc.running = true;
            }
        }
    }

    // Fetch range process (fetches one item at a time with batching)
    QtObject {
        id: fetchRangeProc
        
        property int startIndex: 0
        property int endIndex: 0
        property bool isIncremental: false
        property bool running: false
        property var fetchedItems: []
        property int currentBatch: 0
        
        onRunningChanged: {
            if (running) {
                console.log("[Clipboard] fetchRange running: start=" + startIndex + ", end=" + endIndex + ", maxConcurrency=" + maxConcurrency);
                fetchedItems = [];
                currentBatch = 0;
                fetchNextBatch();
            }
        }
        
        function fetchNextBatch() {
            const batchStart = startIndex + currentBatch * maxConcurrency;
            const batchEnd = Math.min(batchStart + maxConcurrency, endIndex);
            
            if (batchStart >= endIndex) {
                // All batches done
                console.log("[Clipboard] fetchRange complete; finalizing");
                finalizeFetch();
                return;
            }
            
            // Fetch items in this batch
            console.log("[Clipboard] Fetching batch #" + currentBatch + ": " + batchStart + ".." + (batchEnd-1));
            for (let i = batchStart; i < batchEnd; i++) {
                fetchSingleItem(i);
            }
        }
        
        function fetchSingleItem(index) {
            const proc = itemFetchComponent.createObject(root, {
                itemIndex: index
            });
        }
        
        function onItemFetched(item) {
            fetchedItems.push(item);
            
            const expectedInBatch = Math.min(
                (currentBatch + 1) * maxConcurrency,
                endIndex
            ) - startIndex - currentBatch * maxConcurrency;
            
            const receivedInBatch = fetchedItems.length - currentBatch * maxConcurrency;
            
            console.log("[Clipboard] Item fetched idx=" + item.index + ", type=" + item.type + "; batch received=" + receivedInBatch + "/" + expectedInBatch);
            if (receivedInBatch >= expectedInBatch) {
                currentBatch++;
                fetchNextBatch();
            }
        }
        
        function finalizeFetch() {
            if (isIncremental) {
                // Merge with existing items
                const delta = endIndex - startIndex;
                const shifted = clipboardItems.map(it => {
                    const newItem = itemComponent.createObject(root);
                    newItem.index = it.index + delta;
                    newItem.text = it.text;
                    newItem.preview = it.preview;
                    newItem.type = it.type;
                    newItem.imagePath = it.imagePath;
                    return newItem;
                });
                
                const merged = [...fetchedItems, ...shifted];
                merged.sort((a, b) => a.index - b.index);
                clipboardItems = merged;
                lastKnownCount = lastKnownCount + delta;
                console.log("[Clipboard] Incremental fetch merged; delta=" + delta + ", new count=" + clipboardItems.length);
            } else {
                // Full replace
                fetchedItems.sort((a, b) => a.index - b.index);
                clipboardItems = fetchedItems;
                lastKnownCount = fetchedItems.length;
                console.log("[Clipboard] Full fetch complete; count=" + clipboardItems.length);
            }
            
            if (currentPage > totalPages - 1) {
                currentPage = Math.max(0, totalPages - 1);
            }
            
            running = false;
        }
    }

    Component {
        id: itemFetchComponent
        
        QtObject {
            id: itemFetch
            
            property int itemIndex: 0
            
            Component.onCompleted: {
                console.log("[Clipboard] itemFetch start index=" + itemFetch.itemIndex);
                formatCheckProc.running = true;
            }
            
            readonly property Process formatCheckProc: Process {
                command: ["copyq", "read", "?", itemFetch.itemIndex.toString()]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const formats = text.split("\n").filter(f => f.trim());
                        const hasImage = formats.some(f => f.includes("image/png") || f.includes("image/jpeg"));
                        
                        if (hasImage) {
                            // Fetch as image
                            console.log("[Clipboard] idx=" + itemFetch.itemIndex + " has image; using imageFetchProc");
                            itemFetch.imageFetchProc.running = true;
                        } else if (formats.includes("text/html")) {
                            // Fetch as HTML
                            console.log("[Clipboard] idx=" + itemFetch.itemIndex + " has html; using htmlFetchProc");
                            itemFetch.htmlFetchProc.running = true;
                        } else if (formats.some(f => f.includes("text/plain"))) {
                            // Fetch as text
                            console.log("[Clipboard] idx=" + itemFetch.itemIndex + " has text/plain; using textFetchProc");
                            itemFetch.textFetchProc.running = true;
                        } else {
                            // Non-text item
                            console.log("[Clipboard] idx=" + itemFetch.itemIndex + " non-text; creating placeholder");
                            itemFetch.createNonTextItem(formats);
                        }
                    }
                }
            }
            
            readonly property Process textFetchProc: Process {
                command: ["copyq", "read", "text/plain", itemFetch.itemIndex.toString()]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const decoded = root.decodeEscapedText(text).trim();
                        const item = itemComponent.createObject(root);
                        item.index = itemFetch.itemIndex;
                        item.text = decoded;
                        item.preview = decoded.length > root.previewLength 
                            ? decoded.substring(0, root.previewLength) + "..." 
                            : decoded;
                        item.type = decoded.includes("\n") ? "multiline" : "text";
                        
                        fetchRangeProc.onItemFetched(item);
                        console.log("[Clipboard] text item prepared idx=" + item.index + ", previewLen=" + item.preview.length);
                        itemFetch.destroy();
                    }
                }
            }
            
            readonly property Process htmlFetchProc: Process {
                command: ["copyq", "read", "text/plain", itemFetch.itemIndex.toString()]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const decoded = root.decodeEscapedText(text).trim();
                        const item = itemComponent.createObject(root);
                        item.index = itemFetch.itemIndex;
                        item.text = decoded || "[HTML]";
                        item.preview = decoded.length > 0 && decoded.length <= root.previewLength
                            ? decoded
                            : (decoded.length > root.previewLength 
                                ? decoded.substring(0, root.previewLength) + "..."
                                : "[HTML content]");
                        item.type = "html";
                        
                        fetchRangeProc.onItemFetched(item);
                        console.log("[Clipboard] html item prepared idx=" + item.index + ", previewLen=" + item.preview.length);
                        itemFetch.destroy();
                    }
                }
            }
            
            readonly property Process imageFetchProc: Process {
                // Compose the bash command without template literals for QML compatibility
                command: ["bash", "-c", 
                    "copyq read image/png " + itemFetch.itemIndex.toString() + 
                    " > /tmp/clipboard-image-" + itemFetch.itemIndex.toString() + 
                    ".png 2>/dev/null && echo /tmp/clipboard-image-" + itemFetch.itemIndex.toString() + 
                    ".png || echo \"\""
                ]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const path = text.trim();
                        const item = itemComponent.createObject(root);
                        item.index = itemFetch.itemIndex;
                        item.text = "[image]";
                        item.preview = "[Image]";
                        item.type = "image";
                        item.imagePath = path || "";
                        
                        fetchRangeProc.onItemFetched(item);
                        console.log("[Clipboard] image item prepared idx=" + item.index + ", pathPresent=" + (item.imagePath !== ""));
                        itemFetch.destroy();
                    }
                }
            }
            
            function createNonTextItem(formats) {
                const item = itemComponent.createObject(root);
                item.index = itemFetch.itemIndex;
                item.text = formats.length > 0 ? ("[" + formats[0] + "]") : "[unknown data]";
                item.preview = formats.length > 0 ? ("[" + formats[0] + "]") : "[unknown data]";
                item.type = "non-text";
                
                fetchRangeProc.onItemFetched(item);
                console.log("[Clipboard] non-text item prepared idx=" + item.index);
                itemFetch.destroy();
            }
        }
    }

    Component {
        id: itemComponent
        
        QtObject {
            property int index: 0
            property string text: ""
            property string preview: ""
            property string type: "text"
            property string imagePath: ""
        }
    }

    // Select process
    Process {
        id: selectProc
    }

    // Remove process
    Process {
        id: removeProc
    }

    // Clear history process
    Process {
        id: clearProc
        command: ["copyq", "eval", "for(i=size()-1; i>0; --i) remove(i);"]
        onExited: {
            console.log("[Clipboard] clearProc exited; triggering full refresh");
            fullRefreshProc.running = true;
        }
    }

    // Initialize on first visibility
    onVisibleChanged: {
        console.log("[Clipboard] visible changed -> " + visible);
        if (visible && clipboardItems.length === 0) {
            console.log("[Clipboard] First-time visible and no items; starting full refresh");
            fullRefreshProc.running = true;
        }
    }
}

