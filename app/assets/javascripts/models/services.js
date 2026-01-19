$(document).ready(function () {

    let SERVICE_CATEGORY_ID = 'service_category_id';
    let DIV_WITH_PARTS_DATA = 'div-with-parts-data';

    $(document).on('change', '#' + SERVICE_CATEGORY_ID, function () {
        let value = $(this).find(":selected").val();
        if (value == 1) {
            hideElement(DIV_WITH_PARTS_DATA, false);
        } else {
            hideElement(DIV_WITH_PARTS_DATA, true);
        }
    });

});
