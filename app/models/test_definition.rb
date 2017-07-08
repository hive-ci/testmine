class TestDefinition < ActiveRecord::Base
  belongs_to :suite
  belongs_to :parent,   foreign_key: 'parent_id', class_name: 'TestDefinition'
  has_many   :children, foreign_key: 'parent_id', class_name: 'TestDefinition', dependent: :destroy
  has_many   :results
  acts_as_taggable
  default_scope { includes(:tags) }

  def self.find_or_create(args)
    TestDefinition.where(
      name: args[:name],
      suite_id: args[:suite_id],
      file: args[:file],
      parent_id: args[:parent_id]
    ).first_or_create do |test|
      test.name        = args[:name]
      test.node_type   = args[:node_type]
      test.description = args[:description]
      test.file        = args[:file]
      test.line        = args[:line]
      test.parent_id   = args[:parent_id]
      test.tag_list    = args[:tags]
    end
  end

  def specific_tags
    @specific_tags = tags.collect(&:name) unless @specific_tags
    @specific_tags
  end

  def inherited_tags
    unless @inherited_tags
      all = tags.collect(&:name)
      all += parent.inherited_tags if parent
      all.uniq
      @inherited_tags = all.uniq
    end
    @inherited_tags
  end

  def add_test_definition(args)
    args[:suite_id]  = suite_id
    args[:parent_id] = id
    args[:file]      = file unless args[:file]
    TestDefinition.find_or_create(args)
  end

  def file_name(modifier = :short)
    file_name = file
    if modifier == :short
      file =~ /.*features\/(.*.feature)/
      file_name = Regexp.last_match(1) if Regexp.last_match(1)
    end
    file_name
  end
end
