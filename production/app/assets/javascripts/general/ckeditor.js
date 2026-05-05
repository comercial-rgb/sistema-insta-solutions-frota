'use strict';

$(document).ready(function () {
    const tags = document.querySelectorAll('.ck-editor');

    tags.forEach(function(tag) {
        ClassicEditor
            .create(tag, {
                language: 'pt-br',
                licenseKey: '',
                image: { toolbar: [] },
                table: { contentToolbar: [] }
            })
            .then(function(editor) {
                window.editor = editor;
            })
            .catch(function(error) {
                console.error('CKEditor error:', error);
            });
    });
});

// End of file ckeditor.js
// Path: ./app/assets/javascripts/ckeditor.js
