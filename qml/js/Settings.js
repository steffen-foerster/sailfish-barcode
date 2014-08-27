/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

.pragma library

.import "LocalStore.js" as LocalStore

var keys = {
    SOUND: "sound",
    DIGITAL_ZOOM: "digital_zoom",
    SCAN_DURATION: "scan_duration",
    RESULT_VIEW_DURATION: "result_view_duration",
    MARKER_COLOR: "marker_color"
}

var dBValues = {
    B_TRUE: "true",
    B_FALSE: "false"
}

function get(key) {
    return LocalStore.get(key);
}

function getBoolean(key) {
    return LocalStore.get(key) === dBValues.B_TRUE;
}

function set(key, value) {
    LocalStore.set(key, value);
}

function setBoolean(key, value) {
    var booleanStr = value ? dBValues.B_TRUE : dBValues.B_FALSE;
    LocalStore.set(key, booleanStr);
}

/**
 * Should be invoked after application start.
 */
function initialize() {
    var defaultValues = {
        sound: dBValues.B_FALSE,
        digital_zoom: 3,
        scan_duration: 20,
        result_view_duration: 2,
        marker_color: "#00FF00"
    }

    LocalStore.initializeDatabase(defaultValues);
}
