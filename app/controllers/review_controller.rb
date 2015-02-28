class ReviewController < ApplicationController
  def index
  end

  def papers
    @incomplete = {}
    Body.all.each do |b|
      @incomplete[b.state] = []
      @incomplete[b.state].concat Paper.where(['published_at > ?', Date.today])
      @incomplete[b.state].concat Paper.where(page_count: nil).limit(50)
      @incomplete[b.state].concat Paper.find_by_sql(
        ["SELECT p.* FROM papers p LEFT OUTER JOIN paper_originators o ON (o.paper_id = p.id AND o.originator_type = 'Person') WHERE p.body_id = ? AND o.id IS NULL", b.id]
      )
      @incomplete[b.state].concat Paper.find_by_sql(
        ["SELECT p.* FROM papers p LEFT OUTER JOIN paper_answerers a ON (a.paper_id = p.id AND a.answerer_type = 'Ministry') WHERE p.body_id = ? AND a.id IS NULL", b.id]
      )
      @incomplete[b.state].uniq!
    end
  end

  def ministries
    @ministries = Ministry.where('length(name) > 70 OR length(name) < 15')
  end
end