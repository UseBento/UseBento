// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery.fullscreener.min.js
//= require jquery.magnific-popup.min.js
//= require jquery.selectbox-0.2.min.js
//= require validator.js
//= require jquery.touchSwipe.min.js
//= require jquery.carouFredSel-6.2.1-packed.js
//= require functions.js

function do_nothing() {}

function remove_element(element) {
    if (element && element.parentNode)
        element.parentNode.removeChild(element); }

function param_returner(name) {
    return function(obj) {
        return obj[name]; }; }

function delay(that) {
    var args = _to_array(arguments).slice(1);

    return function() {
        var as = args.concat(_to_array(arguments));
        return that.apply(that, as); }; }
var curry = delay;

function _to_array(what) {
    var i; 
    var ar = [];
 
    for (i = 0; i < what.length; i++) {
        ar.push(what[i]); }

    return ar; }

function member(ar, value) {
    return ar.indexOf(value) >= 0; }

function remove_from_set(set, value) {
    return set.filter(function(i) { 
        return i != value; }); }

function navigate(url) {
    window.location.href = url; }

function only_numbers(string) {
    return string.replace(/[^*#0-9]/g, ""); }

function toggleVisible(el) {
    el.style.display =  (el.style.display == 'block') ? 'none' : 'block'; }

function prepend(el, to) {
    var chldren = to.childNodes;
    if (children.length == 0)
        to.appendChild(el);
    else
        to.insertBefore(el, children[0]);
    return el; }


function hash(obj) {
    if (typeof obj != "string")
        obj = JSON.stringify(obj); 
    var hash = 0, i, chr, len;
    if (obj.length == 0) return hash;
    for (i = 0, len = obj.length; i < len; i++) {
        chr   = obj.charCodeAt(i);
        hash  = ((hash << 5) - hash) + chr;
        hash |= 0; // Convert to 32bit integer 
  }
  return hash;
}

function tag_maker(tag) {
    return function(klass, children, click) {
        click = click || do_nothing;
        var obj;

        if (typeof klass != "string") 
            obj = klass;
        else
            obj = {"class": klass};

        obj.tag = tag;
        obj.children = children;
        obj.click = click;
        return obj; }; }

var div =    tag_maker('div');
var span =   tag_maker('span');
var button = tag_maker('button');
var a =      tag_maker('a');
var i =      tag_maker('i');
var li =     tag_maker('li');
var h4 =     tag_maker('h4');
var img =    tag_maker('img');
var strong = tag_maker('strong');
var p =      tag_maker('p');
var select = tag_maker('select');
var input  = tag_maker('input');
var option = tag_maker('option');
var label  = tag_maker('label');
var textarea = tag_maker('textarea');

function br() {
    return {tag: 'br'}; }

function build_el(el) {
    if (el === null) 
        el = {tag: "div"}; 
    if (typeof el == "string") 
        return $(document.createTextNode(el)); 

    var attrs = {};
    for (var i in el) 
        if (i != 'tag'
            && i != 'click'
            && i != 'children')
            attrs[i] = el[i];

    var element = $('<' + el.tag + '/>', attrs);
    if (el.click)
        element.click(el.click);

    var children = (el.children || [])
            .map(build_el);
    for (i in children) 
        element.append(children[i]);

    return element; }

function without_params(obj, params) {
    var return_obj = {};
    for (var i in obj) 
        if (!member(params, i))
            return_obj[i] = obj[i]; 
    return return_obj; }

function depluralize(string) {
    if (string[string.length - 1].toLowerCase() == 's')
        return string.slice(0,-1); 
    return string; }

function o(fn1, fn2) {
    return function(param) {
        return fn1(fn2(param)); }; }
