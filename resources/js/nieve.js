/**
 * jquery.snow - jQuery Snow Effect Plugin
 *
 * Available under MIT licence
 *
 * @version 1 (21. Jan 2012)
 * @author Ivan Lazarevic
 * @requires jQuery
 * @see http://workshop.rs
 *
 * @params minSize - min size of snowflake, 10 by default
 * @params maxSize - max size of snowflake, 20 by default
 * @params newOn - frequency in ms of appearing of new snowflake, 500 by default
 * @params flakeColor - color of snowflake, #FFFFFF by default
 * @example $.fn.snow({ maxSize: 200, newOn: 1000 });
 */


/** (function($){$.fn.snow=function(options){var $flake=$('<div id="flake" />').css({'position':'absolute','top':'-50px'}).html('&#10052;'),documentHeight=$(document).height(),documentWidth=$(document).width(),defaults={minSize:10,maxSize:20,newOn:500,flakeColor:"#FFFFFF"},options=$.extend({},defaults,options);var interval=setInterval(function(){var startPositionLeft=Math.random()*documentWidth-100,startOpacity=0.5+Math.random(),sizeFlake=options.minSize+Math.random()*options.maxSize,endPositionTop=documentHeight-40,endPositionLeft=startPositionLeft-100+Math.random()*200,durationFall=documentHeight*10+Math.random()*5000;$flake.clone().appendTo('body').css({left:startPositionLeft,opacity:startOpacity,'font-size':sizeFlake,color:options.flakeColor}).animate({top:endPositionTop,left:endPositionLeft,opacity:0.2},durationFall,'linear',function(){$(this).remove()});},options.newOn);};})(jQuery); */

(function($) {
    $.fn.snow = function(options) {
        var $flake = $('<div id="flake" />').css({
            'position': 'absolute',
            'top': '-50px'
        }).html('&#10052;'); // Símbolo del copo de nieve

        var documentHeight = $(document).height();
        var documentWidth = $(document).width();

        var defaults = {
            minSize: 10,
            maxSize: 20,
            newOn: 500,
            flakeColor: '#FFFFFF' // Color por defecto (no se usará directamente aquí)
        };

        var options = $.extend({}, defaults, options);

        var interval = setInterval(function() {
            var startPositionLeft = Math.random() * documentWidth;
            var startOpacity = 0.5 + Math.random();
            var sizeFlake = options.minSize + Math.random() * options.maxSize;
            var endPositionTop = documentHeight - 40;
            var endPositionLeft = startPositionLeft - 100 + Math.random() * 200;
            var durationFall = documentHeight * 10 + Math.random() * 5000;

            // Alternar entre blanco y azul
            var colors = ['#FFFFFF', '#007BFF']; // Blanco y azul
            var randomColor = colors[Math.floor(Math.random() * colors.length)];

            $flake.clone().appendTo('body').css({
                left: startPositionLeft,
                opacity: startOpacity,
                'font-size': sizeFlake,
                color: randomColor // Asignar el color alternado aquí
            }).animate({
                top: endPositionTop,
                left: endPositionLeft,
                opacity: 0.2
            }, durationFall, 'linear', function() {
                $(this).remove();
            });
        }, options.newOn);
    };
})(jQuery);
