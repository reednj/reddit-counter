
class Counter {
    constructor(data) {
        this.data = data;
        this.startTime = Date.now();
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
}

class CommentHandler {
    constructor() {
        this.comments = [];
    }

    // this will return the next recent comment. It will refresh the data from the
    // server when it runs out of cached comments. Because it this it always returns
    // a promise, even if it has the data already.
    next() {
        this.comments = this.comments || [];

        if(!this.comments || this.comments.length == 0) {
            return this.getMore().then(comments => {
                this.comments = comments;
                return this.comments.pop();
            });
        } else {
            return Promise.resolve(this.comments.pop());
        }
    }

    getMore() {
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
    constructor() {
        this.handler = new CommentHandler(); 
        this.commentCounter = new Counter(_js.comments);
        $('.recent-comment a.refresh-link').click(e => this.updateComment());
    }

    start() {
        setInterval(() => $('.comments .count').html(this.commentCounter.currentString), 100);
        setInterval(() => this.updateComment(), 10000);
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
