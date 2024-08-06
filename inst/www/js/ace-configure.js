// Ace editor configuration options:
// https://github.com/ajaxorg/ace/wiki/Configuring-Ace#editor-options

//////////////////////////////////////////////
// Configure of the ggplot code editor

var editor_code = ace.edit("editor_code");

//editor.session.setMode("ace/mode/javascript");
// pass options to ace.edit
//ace.edit(element, {
//    mode: "ace/mode/r",
//    selectionStyle: "text",
//    })

// use setOptions method to set several options at once
editor_code.setOptions({
    mode: "ace/mode/r",
    selectionStyle: "text",
    maxLines: 36,
    minLines: 12,
    autoScrollEditorIntoView: true,
    copyWithEmptySelection: true,
    enableBasicAutocompletion: true,
    enableLiveAutocompletion: true,
    enableSnippets: true,
    //showInvisibles: true,
    highlightActiveLine: false,
});
// use setOptions method
editor_code.setOption("mergeUndoDeltas", "always");

// set wrap limit range
editor_code.session.setUseWrapMode(true);

// some options are also available as methods e.g. 
//editor.setTheme("ace/theme/github_light_default");
editor_code.setTheme("ace/theme/tomorrow_night");

// to get the value of the option use
//editor.getOption("optionName");

// read in the json file from "./js/ggplot2.json"
fetch("./js/ggplot2.json")
    .then(response => response.json())
    .then(data => {
        //console.log(data);
        editor_code.completers.push({
            getCompletions: function(editor_code, session, pos, prefix, callback) {
                callback(null, 
                    data
                );
            }
        })
    });

//////////////////////////////////////////////
// Configure of the dataset editor

var editor_data = ace.edit("editor_data");

// The dataset editor is read-only
editor_data.setReadOnly(true);

editor_data.setOptions({
    mode: "ace/mode/r",
    selectionStyle: "text",
    maxLines: 36,
    minLines: 12,
    autoScrollEditorIntoView: true,
    copyWithEmptySelection: true,
    showGutter: false,
    //highlightActiveLine: false,
});

editor_data.setTheme("ace/theme/tomorrow_night");
