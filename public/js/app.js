
class Counter {
    constructor(data, options) {
        this.data = data;
        this.options = options || {};
        this.startTime = Date.now();
        this._lastUpdate = Date.now();
     
        setInterval(() => this._refreshIfNeeded(), 5000);
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
        });
    }

    _refreshIfNeeded() {
        let max_age_sec = this.data.refresh_in || 300;
        let age_in_sec = (Date.now() - this._lastUpdate) / 1000;

        if(age_in_sec > max_age_sec) {
            this.refreshData();
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
    }

    start() {
        setInterval(() => $('.comments .count').html(this.commentCounter.currentString), 100);
        this.updateTimer = setInterval(() => this.updateComment(), 10000);
        this.updateComment();
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
