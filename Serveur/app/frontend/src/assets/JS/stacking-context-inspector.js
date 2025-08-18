// stacking-context-inspector.js – Autonome et sans dépendance externe
(function () {
    if (window.__STACKING_CONTEXT_INSPECTOR_LOADED__) return;
    window.__STACKING_CONTEXT_INSPECTOR_LOADED__ = true;

    // === Toggle Button ===
    const toggleButton = document.createElement('button');
    toggleButton.textContent = '🟣 Toggle Stacking Contexts';
    Object.assign(toggleButton.style, {
        position: 'fixed',
        bottom: '1rem',
        right: '1rem',
        zIndex: 10000000,
        padding: '0.5rem 1rem',
        background: '#000',
        color: '#fff',
        border: '2px solid #ff00ff',
        fontFamily: 'monospace',
        fontSize: '12px',
        borderRadius: '6px',
        cursor: 'pointer',
        opacity: 0.85
    });
    document.body.appendChild(toggleButton);

    // === Overlay state & throttle ===
    let overlays = [];
    let highlightedContexts = [];
    let inspectorEnabled = false;
    let rafId = null;
    let lastRefresh = 0;
    let throttleTimeout = null;
    let mutationObserver = null;

    // Remove all overlays and reset state
    function clearStackingContextOutlines() {
        overlays.forEach(o => o.remove());
        overlays = [];
        highlightedContexts = [];
    }

    // Stacking context detection criteria (same logic as before)
    function stackingCriteria(el) {
        const style = getComputedStyle(el);
        return (
            style.zIndex !== "auto" ||
            style.transform !== "none" ||
            style.opacity < 1 ||
            style.mixBlendMode !== "normal" ||
            style.filter !== "none" ||
            style.perspective !== "none" ||
            style.clipPath !== "none" ||
            style.mask !== "none" ||
            (style.position !== "static" && style.zIndex !== "auto")
        );
    }

    // Overlay creation for a given element
    function highlightElement(el) {
        const overlay = document.createElement("div");
        overlay.className = "stacking-context-highlight";
        Object.assign(overlay.style, {
            position: "absolute",
            top: `${el.offsetTop}px`,
            left: `${el.offsetLeft}px`,
            width: `${el.offsetWidth}px`,
            height: `${el.offsetHeight}px`,
            border: "2px solid #ff00ff",
            background: "rgba(255,0,255,0.05)",
            zIndex: 999999,
            pointerEvents: "none",
            mixBlendMode: "difference"
        });

        const label = document.createElement("div");
        label.textContent = `[z-index: ${getComputedStyle(el).zIndex}] ${el.tagName.toLowerCase()}`;
        Object.assign(label.style, {
            position: "absolute",
            top: "-1.5rem",
            left: "0",
            background: "black",
            color: "lime",
            fontSize: "12px",
            padding: "2px 4px",
            fontFamily: "monospace",
            zIndex: 9999999,
            pointerEvents: "none"
        });

        overlay.appendChild(label);
        if (el.parentNode) {
            el.parentNode.appendChild(overlay);
        }
        overlays.push(overlay);
        highlightedContexts.push({ element: el, overlay, label });
    }

    // Main refresh function (called throttled)
    function refreshStackingContexts() {
        clearStackingContextOutlines();
        // Avoid blocking: only scan visible elements
        // Use requestAnimationFrame for smoothness
        rafId && cancelAnimationFrame(rafId);
        rafId = requestAnimationFrame(() => {
            const all = document.querySelectorAll("*");
            all.forEach((el) => {
                if (stackingCriteria(el)) {
                    highlightElement(el);
                }
            });
            rafId = null;
        });
        lastRefresh = Date.now();
    }

    // Throttle wrapper (500ms min between calls)
    function throttledRefresh() {
        const now = Date.now();
        if (now - lastRefresh > 500) {
            refreshStackingContexts();
        } else if (!throttleTimeout) {
            throttleTimeout = setTimeout(() => {
                refreshStackingContexts();
                throttleTimeout = null;
            }, 500 - (now - lastRefresh));
        }
    }

    // Attach lightweight listeners (no direct recursion/loops)
    function startListeners() {
        window.addEventListener("scroll", throttledRefresh, { passive: true });
        window.addEventListener("resize", throttledRefresh, { passive: true });
        mutationObserver = new MutationObserver(throttledRefresh);
        mutationObserver.observe(document.body, {
            attributes: true,
            childList: true,
            subtree: true,
        });
    }

    // Remove listeners/observers and overlays
    function stopInspector() {
        clearStackingContextOutlines();
        window.removeEventListener("scroll", throttledRefresh, { passive: true });
        window.removeEventListener("resize", throttledRefresh, { passive: true });
        if (mutationObserver) {
            mutationObserver.disconnect();
            mutationObserver = null;
        }
        if (rafId) {
            cancelAnimationFrame(rafId);
            rafId = null;
        }
        if (throttleTimeout) {
            clearTimeout(throttleTimeout);
            throttleTimeout = null;
        }
        inspectorEnabled = false;
    }

    // Toggle logic
    toggleButton.addEventListener('click', () => {
        if (inspectorEnabled) {
            stopInspector();
        } else {
            // Re-initialize
            document.body.appendChild(toggleButton);
            inspectorEnabled = true;
            refreshStackingContexts();
            startListeners();
        }
    });

    // Initial activation is disabled by default.
    // refreshStackingContexts();
    // startListeners();
    console.log("🟣 Stacking Context Inspector is loaded (disabled by default).");
})();