'use strict';

$(document).ready(function () {
    const selector = '.ck-editor';
    const tags = document.querySelectorAll( '.ck-editor' );

    for (let x in tags) {
        ClassicEditor
            .create(tags[x], {
                language: 'pt-br',
                licenseKey: ''
            })
            .then( editor => {
                window.editor = editor;
            })
            .catch( error => {
                console.error( 'Oops, something went wrong!' );
                console.error( 'Please, report the following error on https://github.com/ckeditor/ckeditor5/issues with the build id and the error stack trace:' );
                console.warn( 'Build id: 12fj0jz2sgki-ur0ww7bkj309' );
                console.error( error );
            });
    }
});

// End of file ckeditor.js
// Path: ./app/assets/javascripts/ckeditor.js
