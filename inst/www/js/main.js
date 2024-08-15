// Jquery is enabled in the html file

// Function to get the ggplot data structure from the server
function strData() {
    // Get the figure id
    let figure_id = $("#et_figure_id").text();
    let baseUrl = window.location.origin;
    let url = baseUrl + "/fd_str_data?id=" + figure_id;
    $.ajax({
        url: url,
        type: "GET",
        success: function (data) {
            console.log(data);
            // Show the data in the #editor_data
            //$("#editor_data").val(data);
            editor_data.setValue(data, -1);
        },
    });
}

// Function to order the figure list by name or updated date
function orderFigureList() {
    if (global_figure_order_by == "name") {
        global_figureList.sort(function (a, b) {
            // If two figures have the same name, 
            // then the order should be decided by updated date
            if (a.name == b.name) {
                return a.updated_date.localeCompare(b.updated_date);
            } else {
                return a.name.localeCompare(b.name);
            }
        });
    } else if (global_figure_order_by == "updated_date") {
        global_figureList.sort(function (a, b) {
            return a.updated_date.localeCompare(b.updated_date);
        });
    }
}

// Function to download the data table of the figure
function downloadData() {
    // Get the figure id
    let figure_id = $("#et_figure_id").text();
    let figure_name = $("#et_figure_name").text();
    let baseUrl = window.location.origin;
    let url = baseUrl + "/fd_download_data?id=" + figure_id;
    $.ajax({
        url: url,
        type: "GET",
        success: function (data) {
            console.log(data);
            // Force the browser to download the file
            window.open(baseUrl + "/tmp/" + figure_name + ".csv");
        },
    });
}

// Function to download the figure as a PDF file
function downloadPDF() {
    // Get the figure id
    let figure_id = $("#et_figure_id").text();
    let figure_name = $("#et_figure_name").text();
    let baseUrl = window.location.origin;
    let url = baseUrl + "/fd_download_pdf?id=" + figure_id;
    $.ajax({
        url: url,
        type: "GET",
        success: function (data) {
            console.log(data);
            // Force the browser to download the file
            window.open(baseUrl + "/tmp/" + figure_name + ".pdf");
        },
    });
}

// Change the figure name
function changeFigureName() {
    // Get the old name
    let old_name = $("#et_figure_name").text();
    // Popup a dialog to get the new name
    let new_name = prompt("Please enter the new name", old_name);
    // the new_name can not be empty or full of space
    if (new_name == "" || new_name.trim() == "") {
        // popup a dialog to warn the user
        alert("The name cannot be empty");
    } else if (new_name == null) {
        // If the user click "Cancel", do nothing
    } else if (new_name != old_name) {
        // Get the figure id
        let figure_id = $("#et_figure_id").text();
        let baseUrl = window.location.origin;
        let url = baseUrl + "/fd_change_name?id=" + figure_id + "&new_name=" + new_name;
        $.ajax({
            url: url,
            type: "GET",
            success: function (data) {
                console.log(data);
                // Update the figure name in the global_figureList
                for (let i = 0; i < global_figureList.length; i++) {
                    if (global_figureList[i].id == figure_id) {
                        global_figureList[i].name = new_name;
                        break;
                    }
                }
                // Update the figure name in the edit container
                $("#et_figure_name").text(new_name);
            },
        });
    }
}

// Delete the figure
function deleteFigure() {
    // get the parent id
    let figure_id = $("#et_figure_id").text();
    let baseUrl = window.location.origin;

    console.log(figure_id);

    // Use dialog to confirm the delete action
    if (confirm("Are you sure you want to delete the figure?")) {
        // if the user click "OK", delete the figure
        let url = baseUrl + "/fd_rm?id=" + figure_id;
        $.ajax({
            url: url,
            type: "GET",
            success: function (data) {
                console.log(data);
                // Delete the figure from the global_figureList
                for (let i = 0; i < global_figureList.length; i++) {
                    if (global_figureList[i].id == figure_id) {
                        global_figureList.splice(i, 1);
                        break;
                    }
                }
                // Delete the figure from the grid
                $("#" + figure_id).remove();
                // Close the edit container
                closeEditContainer();
            },
        });
    }
}


// Get figure object from a list of figures
function getFigure(figure_id, figureList) {
    let figure = {};
    for (let i = 0; i < figureList.length; i++) {
        if (figureList[i].id == figure_id) {
            figure = figureList[i];
            break;
        }
    }
    return figure;
}

// Get font list from server
// NOTE: No longer needed, need to be removed
function getFontList() {
    let fontList;
    let baseUrl = window.location.origin;
    let url = baseUrl + "/fd_font_ls";
    $.ajax({
        url: url,
        type: "GET",
        async: false,
        success: function (data) {
            fontList = data;
        },
    });
    return fontList;
}


// Function to check if the <text> value is changed by the user
// NOTE: No longer needed, need to be removed
function checkChangeText(new_value, old_value) {
    // when new value is "" and old_value is "" or undefined, return false
    // else compare the new value and old value
    if (new_value == "" && (old_value == "" || old_value == undefined)) {
        return false;
    } else {
        if (new_value != old_value) {
            return true;
        } else {
            return false;
        }
    }
}

// Get figure list and info from server
function getFigureList() {
    let figureList;
    let baseUrl = window.location.origin;
    let url = baseUrl + "/fd_ls";
    $.ajax({
        url: url,
        type: "GET",
        async: false,
        success: function (data) {
            figureList = data;
        },
    });
    return figureList;
}

// Function to link the figure image to grid
function linkFigure(img, figure) {
    let baseUrl = window.location.origin;
    img.attr(
        "src",
        baseUrl + "/figure/" +
            figure.file_name +
            "?" +
            figure.updated_date,
    );
    img.attr("alt", figure.id);
    return img;
}

// Update the info in the figure edit container
function updateEditToolHtml(figure) {
    // Update figure name
    $("#et_figure_name").text(figure.name);

    // Update figure id
    $("#et_figure_id").text(figure.id);
    // Update figure create data
    $("#et_create_date").text(figure.created_date);
    // Update figure update data
    $("#et_update_date").text(figure.updated_date);
    // Update code
    //$("#code").val(figure.code_updated);
    editor_code.setValue(figure.code_updated, 1);

    // Updata canvas size
    $("#height").val(figure.height);
    $("#width").val(figure.width);
    $("#dpi").val(figure.dpi);
    // Update units
    $("#fig_size_units option").each(function () {
        if ($(this).val() == figure.units) {
            $(this).prop("selected", true);
        }
    });

    // Up
}

// Load the figure in the edit container
function loadFigure(figure_id, figureList) {
    // find the figure by name from the figureList
    let figure = getFigure(figure_id, figureList);

    // Update the canvas option
    updateEditToolHtml(figure);

    // display the figure
    let figureDiv = $("#img_canvas");
    figureDiv.empty();
    let img = $("<img>");
    img = linkFigure(img, figure);
    figureDiv.append(img);
}



// NOTE: No longer needed, need to be removed
function preparePlotLabsCode() {
    let gg_code_lab = [];

    // get the labels from the input
    let input_title = $("#et_figure_title").val();
    let input_xlab = $("#et_figure_xlab").val();
    let input_ylab = $("#et_figure_ylab").val();

    if (input_title != "") {
        gg_code_lab.push("labs(title = '" + input_title + "')");
    }

    if (input_xlab != "") {
        gg_code_lab.push("labs(x = '" + input_xlab + "')");
    }

    if (input_ylab != "") {
        gg_code_lab.push("labs(y = '" + input_ylab + "')");
    }

    return gg_code_lab.join(" +\n");
}

// make update figure by POST request
function updateFigurePost(figure_id, gg_code, figureList) {
    let baseUrl = window.location.origin;
    let url = baseUrl + "/fd_update_fig";
    let data = {
        id: figure_id,
        gg_code: gg_code,
    };
    $.ajax({
        url: url,
        async: false,
        // send data in format of JSON
        type: "POST",
        data: JSON.stringify(data),
        contentType: "application/json",
        success: function (data) {
            console.log(data);
            figureList = getFigureList();
            loadFigure(figure_id, figureList);
        },
        error: function (xhr, status, error) {
            if (xhr.status == 400) {
                // Show the error message in the #error_window
                $("#error_window").css("display", "flex");
                $("#error_message").text(xhr.responseText);
                console.log(xhr.responseText);
            }
        },
    });
    return figureList;
}

function updataFigureSize(figure_id, height, width, units, dpi, figureList) {
    let baseUrl = window.location.origin;
    let url =
        baseUrl + "/fd_canvas" +
            "?id =" +
            figure_id +
            "&height=" +
            height +
            "&width=" +
            width +
            "&units=" +
            units +
            "&dpi=" +
            dpi;

    $.ajax({
        url: url,
        async: false,
        type: "GET",
        success: function (data) {
            console.log(data);

            // reload the figure is editor canvas
            figureList = getFigureList();
            loadFigure(figure_id, figureList);
        },
        error: function (xhr, status, error) {
            if (xhr.status == 400) {
                // Show the error message in the #error_window
                $("#error_window").css("display", "flex");
                $("#error_message").text(xhr.responseText);
                console.log(xhr.responseText);
            }
        },
    });
    return figureList;
}

function closeEditContainer() {
    $("#img_edit_container").css("display", "none");

    // Refresh the figure list
    global_figureList = getFigureList();

    // Update the figure grid
    initFigureGrid();

    //let figure_id = $("#img_canvas img").attr("alt");
    //let figure = {};
    //for (let i = 0; i < global_figureList.length; i++) {
        //if (global_figureList[i].id == figure_id) {
            //figure = global_figureList[i];
            //break;
        //}
    //}
    //let img = $("#" + figure.id + " img").first();
    //linkFigure(img, figure);

    // Delete the error message
    $("#error_window").css("display", "none");

    // Delete the code in the textarea
    //$("#code").val("");
    editor_code.setValue("");

    // Hide the mask
    $("#mask").css("display", "none");

}

function initFigureGrid() {
    var container = $("#img_grid_container");
    orderFigureList();
    container.empty();
    for (let i = 0; i < global_figureList.length; i++) {
        let figure = global_figureList[i];
        let figureDiv = $("<div></div>");
        figureDiv.addClass("grid_figure");
        figureDiv.attr("id", figure.id);
        let img = $("<img>");
        linkFigure(img, figure);
        figureDiv.append(img);
        container.append(figureDiv);

        // Add figure name to the figure div
        let figureName = $("<p></p>");
        // Make max length of the name 35 and add "..." at the end
        let figureNameText = figure.name;
        if (figureNameText.length > 35) {
            figureNameText = figureNameText.slice(0, 35) + "...";
        }
        figureName.text(figureNameText);
        figureDiv.append(figureName);

        // When click each figure, show figure edit canvas
        figureDiv.click(function () {
            // Get the figure id
            let figure_id = $(this).attr("id");
            console.log(figure_id);

            // Show the #img_edit_container
            $("#img_edit_container").css("display", "flex");
            $("#mask").css("display", "flex");

            // Load the previous code
            //$("#code").val(figure.code_updated);
            //editor.setValue(figure.code_updated);
            editor_code.setValue(figure.code_updated, 1);


            loadFigure(figure_id, global_figureList);
        });
    }
}


//////////////////
//  Run script  //
//////////////////

// Get font list from server
//var global_fontList = getFontList();
//console.log(global_fontList);
// Add the font list to the select option
//let font_select = $("#et_figure_font_family");
//for (let i = 0; i < global_fontList.length; i++) {
    //let font = global_fontList[i];
    //let option = $("<option></option>");
    //option.attr("value", font);
    //option.text(font);
    //font_select.append(option);
//}

var global_figure_order_by = "name";

// Get the figure list table from server
var global_figureList = getFigureList();

$("#mask").click(function () {
    closeEditContainer();
});

$("#img_edit_container .btn_close").click(function () {
    closeEditContainer();
});

// Generate the figure grid in the container
initFigureGrid();

// Submit changes of canvas
$("#btn_change_canvas").click(function () {
    // Delete the error message
    $("#error_window").css("display", "none");

    // Get the figure id
    let figure_id = $("#img_canvas img").attr("alt");
    // Get the figure from global_figureList
    let figure = getFigure(figure_id, global_figureList);

    // If the height and width are changed, update the figure
    let height = $("#height").val();
    let width = $("#width").val();
    let dpi = $("#dpi").val();
    // get the units by the select option
    let units = $("#fig_size_units option:selected").val();

    // Update the figure using REST API
    global_figureList = updataFigureSize(
        figure_id,
        height,
        width,
        units,
        dpi,
        global_figureList,
    );
});

// When the button with id "change" is clicked, change the figure size
$("#btn_change_figure").click(function () {
    // Delete the error message
    $("#error_window").css("display", "none");

    // Get the figure id
    let figure_id = $("#img_canvas img").attr("alt");
    // Get the figure from global_figureList
    let figure = getFigure(figure_id, global_figureList);

    // If code textarea is not empty, update the figure
    //let gg_code = $("#code").val();
    let gg_code = editor_code.getValue();
    
    if (gg_code != "") {
        global_figureList = updateFigurePost(figure_id, gg_code, global_figureList);
    }
});


// Close Editor container by ESC key
// Add an event listener to the document
document.addEventListener("keydown", function(event) {
  if (event.key === "Escape" || event.keyCode === 27) {
    closeEditContainer();
  }
});

// Tab of canvas size and ggplot code
$("#bt_canvas").click(function () {
    $("#tab_canvas").css("display", "flex");
    $("#tab_ggplot").css("display", "none");
    $("#tab_data").css("display", "none");
    $("#bt_canvas").addClass("tab_active");
    $("#bt_ggplot").removeClass("tab_active");
    $("#bt_data").removeClass("tab_active");
});

$("#bt_ggplot").click(function () {
    $("#tab_canvas").css("display", "none");
    $("#tab_ggplot").css("display", "flex");
    $("#tab_data").css("display", "none");
    $("#bt_canvas").removeClass("tab_active");
    $("#bt_ggplot").addClass("tab_active");
    $("#bt_data").removeClass("tab_active");
});

$("#bt_data").click(function () {
    $("#tab_canvas").css("display", "none");
    $("#tab_ggplot").css("display", "none");
    $("#tab_data").css("display", "flex");
    $("#bt_canvas").removeClass("tab_active");
    $("#bt_ggplot").removeClass("tab_active");
    $("#bt_data").addClass("tab_active");
    strData();
});

// Order the figure list by name or updated date
$("#btn_order_name").click(function () {
    global_figure_order_by = "name";
    $("#btn_order_name").addClass("tab_active");
    $("#btn_order_date").removeClass("tab_active");
    global_figure_order_by = "name";
    initFigureGrid();
});

$("#btn_order_date").click(function () {
    global_figure_order_by = "updated_date";
    $("#btn_order_name").removeClass("tab_active");
    $("#btn_order_date").addClass("tab_active");
    global_figure_order_by = "updated_date";
    initFigureGrid();
});

// Refresh the figure list by clicking the refresh button
$("#btn_refresh").click(function () {
    global_figureList = getFigureList();
    initFigureGrid();
});
