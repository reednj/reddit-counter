require_relative './redis-json_model'

class RedditThreadRate < RedisJSONModel
    
    def self.key(id)
        "reddit:thread:rate_data:#{id}"
    end

    def self.top_by_rate(n=10)
        # always get at least the top x, so we can do some pruning
        ids = redis.zrevrange 'reddit:thread:rate_data:by_rate', 0, [100, n].max
        threads = ids.map{|id| RedditThreadRate.load(id) }

        prune_ids = threads.
            select{|t| t[:count].nil? }.
            map{|t| t.key.split(':').last }

        self._prune_from_index(prune_ids)
        threads.select{|t| !t[:rate].nil?  }.first(n)
    end

    def self._prune_from_index(ids)
        # need to loop through removing items from the list, as
        # not all versions of redis support removing mulitple
        # keys at once
        ids.each do |id|
            redis.zrem('reddit:thread:rate_data:by_rate', id)
        end
    end

    def update_count(n)
        self[:rate] = calc_new_rate(n.to_i)
        self[:count] = n.to_i
    end

    # rate is in comments per hour, to keep the units reasonable
    def calc_new_rate(new_count)
        return nil if self[:count].nil?
        return self[:rate] if new_count < self[:count]

        time_diff = Time.now.to_f - self[:updated_date]
        new_rate = (new_count - self[:count]) / (time_diff / 3600.0)

        # if the update is very quick, then we don't really have enough
        # comments to get a proper average rate, so do a rolling average
        # with the rate from last time
        return new_rate * 0.5 + (self[:rate]||new_rate) * 0.5 if time_diff < 3*60
        return new_rate
    end

    def key
        self.class.key self[:id]
    end

    def save
        self[:updated_date] = Time.now.to_f
        self[:created_date] ||= self[:updated_date]
        super(self.key)
        self.redis.expire self.key, 15 * 60

        unless self[:rate].nil?
            # rank by rate as well - but we need a different method to get the old ones out
            self.redis.zadd 'reddit:thread:rate_data:by_rate', self[:rate], self[:id]
        end

        return self
    end

    def self.load(id)
        model = super(self.key(id))
        model[:id] = id
        return model
    end

    def subreddit_link
        "https://www.reddit.com/r/#{self[:subreddit]}"
    end

    def thread_link
        "https://www.reddit.com/r/comments/#{thread_id}"
    end

    def thread_id
        self[:id].to_s.split('_').last
    end
end
