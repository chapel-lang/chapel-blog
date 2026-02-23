/* A sticky table of contents lands us in hot water if the user's viewport is
   too small to fit the TOC. Then, as they keep scrolling, the TOC keeps
   up with them, and its bottom remains unreachable. A coarse solution
   is to always keep the TOC at the top when the viewport is too small. */
function unstickToc(toc, viewport) {
    const wrapper = toc.querySelector('.wrapper');
    if (!wrapper) return;

    if (wrapper.offsetHeight > viewport - 50 && !wrapper.classList.contains('overfull')) {
        wrapper.classList.add('overfull');
    } else if (wrapper.offsetHeight <= viewport - 50 && wrapper.classList.contains('overfull')) {
        wrapper.classList.remove('overfull');
    }
}

function setupCurrentHighlighting() {
    // Assumes that the TOC only includes entries from h3 and h4 (currently
    // this is true per the Hugo configuration).
    const elements = document.querySelectorAll('.post-content > h3, .post-content > h4');
    function recomputeVisible() {
        var h3Index = 0;
        var h4Index = 0;
        var TOCul = document.querySelector('#TableOfContents > ul');

        TOCul.querySelectorAll('.current').forEach(function(item) {
            item.classList.remove('current');
        });
        for (var i = 0; i < elements.length; i++) {
            // Use actual window viewport to check this
            let belowViewport = elements[i].getBoundingClientRect().top > 5;

            // While !belowViewport (aka, 'above viewport'), we're
            // iterating over things that we've scrolled by. Increment the
            // indices to track our position in the TOC.
            if (!belowViewport) {
                if (elements[i].tagName === 'H3') {
                    h3Index++;
                    h4Index = 0;
                } else if (elements[i].tagName === 'H4') {
                    h4Index++;
                }
            } else {
                // We've found the first element that is below the viewport.
                // That means the previous element is the last one above the
                // viewport, and should be marked as current.
                if (h3Index > 0) {
                    TOCul.children[h3Index-1].classList.add('current');
                }
                if (h4Index > 0) {
                    // There's a placeholder li if we have h4s without h3s.
                    const h3 = h3Index > 0 ? h3Index - 1 : 0;
                    TOCul
                        .children[h3]
                        .querySelectorAll(':scope > ul > li')[h4Index-1]
                        .classList.add('current');
                }
                break;
            }
        }
    }

    window.addEventListener('popstate', function() {
        recomputeVisible();
    });

    let requested = false;
    window.addEventListener('scroll', function() {
        if (!requested) {
            requested = true;
            window.requestAnimationFrame(function() {
                recomputeVisible();
                requested = false;
            });
        }
    });
}

document.addEventListener('DOMContentLoaded', function() {
    var toc = document.querySelector('.table-of-contents.sticky');
    if (!toc) return;

    setupCurrentHighlighting();

    window.addEventListener('resize', function() {
        unstickToc(toc, window.innerHeight);
    });
    unstickToc(toc, window.innerHeight);
});
