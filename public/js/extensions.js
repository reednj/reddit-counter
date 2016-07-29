
(function () {
	var implement = function(name, fn) {
		if(!this.prototype[name])
			this.prototype[name] = fn;

		return this;
	};

	if(!Function.prototype.implement) {
		Function.prototype.implement = implement;
	}

	if(!Element.prototype.implement) {
		Element.implement = implement;
		Element.prototype.implement = implement;
	}

})();

(function() {
	Function.implement('delay', function(time_ms, scope) {
		return setTimeout(this.bind(scope), time_ms);
	});

	Function.implement('periodical', function(time_ms, scope) {
		return setInterval(this.bind(scope), time_ms);
	});

	Number.implement('round', function() {
		return Math.round(this);
	});
})();