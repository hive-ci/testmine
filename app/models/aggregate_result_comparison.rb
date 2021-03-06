class AggregateResultComparison
  attr_accessor :primary, :reference, :test_definition, :target, :tags

  def initialize(primary_world, reference_world, test_def, target, primary_aggregate_result, reference_aggregate_result, tags)
    @primary         = primary_aggregate_result
    @reference       = reference_aggregate_result
    @test_definition = test_def
    @target          = target
    @primary_world   = primary_world
    @reference_world = reference_world
    @tags            = tags

    unless @primary
      @primary = AggregateResult.new(@test_definition, primary_world, [], target, tags)
    end

    unless @reference
      @reference = AggregateResult.new(@test_definition, reference_world, [], target, tags)
    end
  end

  # Return the comparison status for the primary world
  def status
    unless @status
      status = @primary.status
      if @primary.status == 'pass' && @reference.status != 'pass'
        status = 'newpass'
      elsif @reference.status == 'pass' && @primary.status == 'fail'
        status = 'regres'
      end

      if status.match('pass') && @primary.children.count < @reference.children.count
        status = 'notrun'
      end

      if status == 'pass' && @primary.children.count > @reference.children.count
        status = 'newpass'
      end

      @status = status
    end
    @status
  end

  # Do primary and reference results differ
  def diff
    @primary.status != @reference.status || @primary.children.count != @reference.children.count
  end

  def children
    unless @children

      primary_child_results_by_test   = primary.children.group_by(&:test_definition)
      reference_child_results_by_test = reference.children.group_by(&:test_definition)

      tests = primary_child_results_by_test.keys.concat(reference_child_results_by_test.keys).uniq

      if !primary_child_results_by_test && !reference_child_results_by_test
        @children = []
      else
        @children = tests.collect do |test|
          primary_aggregate = primary_child_results_by_test[test].pop if primary_child_results_by_test[test]
          reference_aggregate = reference_child_results_by_test[test].pop if reference_child_results_by_test[test]

          AggregateResultComparison.new(primary, reference, test, target, primary_aggregate, reference_aggregate, tags)
        end
      end

    end
    @children
  end
end
