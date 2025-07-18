/* Heavily based on a similar script by Jeremiah Corrado. */
for (const selector of document.getElementsByClassName('good-selector')) {
    const options = selector.parentElement.getElementsByClassName('good-option');
    let i = 0;
    for (const option of options) {
        if (i == 0) {
            option.style.display = "block";
        } else {
            option.style.display = "none";
        }

        const htmlOption = document.createElement('option');
        htmlOption.text = option.dataset.label;
        htmlOption.value = option.dataset.suffix;
        selector.add(htmlOption);

        i+= 1;
    }

    selector.addEventListener('change', (e) => {
        for (const option of options) {
            if (option.dataset.suffix == e.target.value) {
                // currently selected option
                option.style.display = "block";
            } else {
                // any other option
                option.style.display = "none";
            }
        }
    })
}

