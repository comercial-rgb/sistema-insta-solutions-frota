$(document).ready(function () {

    let COST_CENTER_HAS_SUB_UNITS = 'cost_center_has_sub_units';
    let DIV_WITH_SUB_UNITS = 'div-with-sub-units';

    $(document).on('change', '#' + COST_CENTER_HAS_SUB_UNITS, function () {
        let value = $(this).find(":selected").val();
        if (value == 'false') {
            hideElement(DIV_WITH_SUB_UNITS, true);
        } else if (value == 'true') {
            hideElement(DIV_WITH_SUB_UNITS, false);
        }
    });

});
