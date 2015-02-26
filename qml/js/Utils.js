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

function isLink(text) {
    var urls = text.match(/^(http[s]*:\/\/.{3,500}|www\..{3,500}|sms:.*)$/);
    var vcard = text.match(/^(.+VCARD.+)$/);
    // is a known url scheme and not a vcard
    return (urls && urls.length > 0 && !(vcard && vcard.length > 0));
}

function isText(text) {
    return !isLink(text);
}

function removeLineBreak(text) {
    return text.replace(/\n/g, " ");
}

function shortenText(text, maxLength) {
    var shortenText = text.replace(/\n/g, " ");
    return shortenText.length > maxLength ? shortenText.substr(0, maxLength) + "..." : shortenText;
}

function formatTimestamp(timestamp) {
    var hours = ("00" + timestamp.getHours()).slice(-2);
    var minutes = ("00" + timestamp.getMinutes()).slice(-2);
    var seconds = ("00" + timestamp.getSeconds()).slice(-2);
    var year = timestamp.getFullYear();
    var month = ("00" + (timestamp.getMonth() + 1)).slice(-2);
    var day = ("00" + timestamp.getDate()).slice(-2);

    return year + "-" + month + "-" + day + "   " + hours + ":" + minutes + ":" + seconds;
}
