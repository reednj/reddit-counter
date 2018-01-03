
class Counter {
    constructor(data, options) {
        this.data = data;
        this.options = options || {};
        this.startTime = Date.now();
        this._lastUpdate = Date.now();
     
        setInterval(() => this._refreshIfNeeded(), 2500);
    }

    get age() {
        return (this.data.age || 0) + (Date.now() - this.startTime) / 1000;
    }

    get currentValue() {
        return this.data.count + this.data.rate * this.age;
    }

    get currentString() {
        return Math.round(this.currentValue).toLocaleString();
    }

    refreshData() {
        this._lastUpdate = Date.now();

        return $.getJSON(this.options.refreshUrl).then(response => {
            this.data = response;
            this.startTime = Date.now();

            // this should be abstracted somehow as the counter is not
            // just for comments. Maybe trigger an event on the parent?
            $('#comment-rate-text').text(`${this._formatN1(this.data.rate)} comments/sec`);
        });
    }

    _refreshIfNeeded() {
        let max_age_sec = this.data.refresh_in || 300;
        let age_in_sec = (Date.now() - this._lastUpdate) / 1000;

        if(age_in_sec > max_age_sec) {
            this.refreshData();
        }
    }

    _formatN1(n) {
        let m = (Math.round(n*10)/10.0).toString();
        return m.includes('.') ? m : m + '.0';
    }
}

class Duration {
    constructor() {
        this._ms = 0;
        this._time = null;
    }

    static since(d) {
        let duration = new Duration();
        duration._time = d || Date.now();
        return duration;
    }

    get ms() {
        return this._time ? Math.abs(Date.now() - this._time) : this._ms;
    }

    get seconds() {
        return this.ms / 1000;
    }

    get minutes() {
        return this.seconds / 60;
    }

    get hours() {
        return this.minutes / 60;
    }

    get days() {
        return this.hours / 24;
    }

    toString() {
        var result = '';

        if(this.days > 1) {
            result = `${Math.floor(this.days)} days `;
        }

        let h = Math.floor(this.hours % 24);
        let m = Math.floor(this.minutes % 60);
        let s = Math.floor(this.seconds % 60);
        
        result += `${this._pad(h)}:${this._pad(m)}:${this._pad(s)}`
        return result;
    }

    _pad(n) {
        n = n || 0;
        if(n >= 10) {
            return n.toString();
        } else {
            return '0' + n.toString();
        }
    }
}

class CommentHandler {
    constructor() {
        this.comments = [];
        this._lastUpdate = null;
        this._updating = false;
    }

    // this will return the next recent comment. It will refresh the data from the
    // server when it runs out of cached comments. Because it this it always returns
    // a promise, even if it has the data already.
    next() {
        this.comments = this.comments || [];

        if(this._updating) {
            return Promise.resolve({});
        }

        // if the downloaded comments are too old, then we will try to 
        // refresh the data to get new ones
        if(this._lastUpdate && Date.now() - this._lastUpdate > 10 * 60 * 1000) {
            this.comments = [];
        }

        if(!this.comments || this.comments.length == 0) {
            this._updating = true;
            return this._getMore().then(comments => {
                this.comments = comments;
                this._updating = false;
                return this.comments.pop();
            });
        } else {
            return Promise.resolve(this.comments.pop());
        }
    }

    _getMore() {
        this._lastUpdate = Date.now();
        let url = 'https://www.reddit.com/r/all/comments.json?sort=new&limit=20';
        return $.getJSON(url)
            .then(response => { 
                return response.data.children
                    .map(c => c.data)
                    .filter(c => c.body.length < 140 && !c.body.includes('http'));
            });
    }
}

class App {
    constructor(options) {
        this.options = options || {};
        this.handler = new CommentHandler(); 
        this.commentCounter = new Counter(this.options.comments || {}, { 
            refreshUrl: '/data/comments.json'
        });

        this.updateTimer = -1;

        $('.recent-comment a.refresh-link').click(e => {
            if(this.updateTimer > 0) {
                clearTimeout(this.updateTimer);
                this.updateTimer = setInterval(() => this.updateComment(), 10000);
            }
            
            this.updateComment();
        });

        $('.top-threads').load('/data/top.html?n=5');
        setInterval(() => $('.top-threads').load('/data/top.html?n=5'), 30 * 1000);

        let milestone_t = $('#milestone-time').attr('data-time');
        if(milestone_t - Date.now()/1000 < 3600 * 24) {
            let duration = Duration.since(milestone_t * 1000);

            $('#milestone-time').show();
            setInterval(() => $('#milestone-time').text('(' + duration.toString() + ')'), 1000);
        }
    }


    start() {
        setInterval(() => $('.comments .count').html(this.commentCounter.currentString), 100);
        this.updateTimer = setInterval(() => this.updateComment(), 10000);
        this.updateComment();
        return this;
    }

    updateComment() {
        this.handler.next().then(comment => {
            $('.recent-comment span').html(comment.body);
            $('.recent-comment a.comment-link')
                .attr('href', `${comment.link_permalink}${comment.id}`);
            $('.recent-comment a.user-link')
                .text(`/u/${comment.author}`)
                .attr('href', `http://reddit.com/u/${comment.author}`);
        });
    }
}
