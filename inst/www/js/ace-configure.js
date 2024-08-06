// Ace editor configuration options:
// https://github.com/ajaxorg/ace/wiki/Configuring-Ace#editor-options

var editor = ace.edit("editor");

//editor.session.setMode("ace/mode/javascript");
// pass options to ace.edit
//ace.edit(element, {
//    mode: "ace/mode/r",
//    selectionStyle: "text",
//    })

// use setOptions method to set several options at once
editor.setOptions({
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
editor.setOption("mergeUndoDeltas", "always");

// set wrap limit range
editor.session.setUseWrapMode(true);

// some options are also available as methods e.g. 
//editor.setTheme("ace/theme/github_light_default");
editor.setTheme("ace/theme/tomorrow_night");

// to get the value of the option use
//editor.getOption("optionName");

// read in the json file from "./js/ggplot2.json"
fetch("./js/ggplot2.json")
    .then(response => response.json())
    .then(data => {
        //console.log(data);
        editor.completers.push({
            getCompletions: function(editor, session, pos, prefix, callback) {
                callback(null, 
                    data
                );
            }
        })
    });

//editor.completers.push({
//    getCompletions: function(editor, session, pos, prefix, callback) {
//        callback(null, 
//            [
//            {value: "foo", score: 1000, meta: "custom"},
//            {value: "bar", score: 1000, meta: "custom"}
//            ]
//        );
//    }
//})
