/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster

I used some ideas of the file
https://github.com/tworaz/sailfish-ytplayer/pages/Settings.js
from Peter Tworek for the below JavaScript.

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

.import QtQuick.LocalStorage 2.0 as Sql

var privateScope = {
    getDatabase : function() {
        return Sql.LocalStorage.openDatabaseSync("CodeReader", "1.0", "Database of application CodeReader", 100000);
    }
}

// ------------------------------------------------------------
// Initialize
// ------------------------------------------------------------

function initializeDatabase(defaultSettings) {
    console.log("initializing database");
    var db = privateScope.getDatabase();
    db.transaction(function(tx) {
        initializeSettings(defaultSettings, tx);
    });
}

function initializeSettings(defaultSettings, tx) {
    tx.executeSql('CREATE TABLE IF NOT EXISTS settings(key TEXT, value TEXT, PRIMARY KEY (key))');
    for (var key in defaultSettings) {
        tx.executeSql('INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?);',
                      [key, defaultSettings[key]]);
    }
    console.debug("Table SETTINGS initialized");
}

// ------------------------------------------------------------
// Settings
// ------------------------------------------------------------

function set(key, value) {
    console.debug("saving setting " + key);
    var db = privateScope.getDatabase();
    db.transaction(function (tx) {
        tx.executeSql('INSERT OR REPLACE INTO settings VALUES(?, ?);', [key, value]);
    });
}

function get(key) {
    var db = privateScope.getDatabase();
    var retval = undefined;
    db.transaction(function (tx) {
        var res = tx.executeSql('SELECT value FROM settings WHERE key = ?;', [key]);
        if (res.rows.length > 0) {
            retval = res.rows.item(0).value;
        } else {
            console.warn("key ", key, " not found!");
            retval = undefined;
        }
    });
    return retval;
}
