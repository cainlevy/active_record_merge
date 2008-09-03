require File.dirname(__FILE__) + '/test_helper'

class ActiveRecordMergeTest < Test::Unit::TestCase
  fixtures :addresses, :roles, :roles_users, :services, :subscriptions, :users

  def test_normal_attribute
    # first try merging records with conflicting values.
    assert_unchanged 'users(:one).name' do
      assert_nothing_raised {users(:one).merge!(users(:two))}
    end

    # then try merging into an empty record
    new_user = User.new
    assert_transfered :name, users(:one), new_user do
      assert_nothing_raised {new_user.merge!(users(:one))}
    end
  end

  def test_polymorphic
    # first try merging records with conflicting values.
    assert_unchanged 'addresses(:one).addressable' do
      assert_nothing_raised {addresses(:one).merge!(addresses(:two))}
    end

    # then try merging into an empty record
    new_address = Address.new
    assert_transfered :addressable, addresses(:one), new_address do
      assert_nothing_raised {new_address.merge!(addresses(:one))}
    end
  end

  def test_belongs_to
    # first try merging records with conflicting values.
    assert_unchanged 'subscriptions(:one).user' do
      assert_nothing_raised {subscriptions(:one).merge!(subscriptions(:two))}
    end

    # then try merging into an empty record
    new_subscription = Subscription.new
    assert_transfered :user, subscriptions(:one), new_subscription do
      assert_nothing_raised {new_subscription.merge!(subscriptions(:one))}
    end
  end

  def test_has_one
    # first try merging records with conflicting values.
    assert_unchanged 'users(:one).address' do
      assert_nothing_raised {users(:one).merge!(users(:two))}
    end

    # then try merging into an empty record
    new_user = User.new
    assert_transfered :address, users(:one), new_user do
      assert_nothing_raised {new_user.merge!(users(:one))}
    end
  end

  def test_has_many
    # just test merging records with existing values
    subscriptions = services(:two).subscriptions
    assert_changed '(services(:one).subscriptions & subscriptions) == subscriptions' do
      assert_nothing_raised {services(:one).merge!(services(:two))}
    end
  end

  def test_has_and_belongs_to_many
    # just test merging records with existing values
    users = roles(:two).users
    assert_changed '(roles(:one).users & users) == users' do
      assert_nothing_raised {roles(:one).merge!(roles(:two))}
    end
  end

  def test_has_many_through
    # just test merging records with existing values
    users = services(:two).users

    assert_changed '(services(:one, :reload).users & users) == users' do
      assert_nothing_raised {services(:one).merge!(services(:two))}
    end
  end

  def test_deletes_other_record
    assert_nothing_raised {users(:one).merge!(users(:two))}
    assert_raise ActiveRecord::RecordNotFound, "other record no longer exists" do User.find(users(:two).id) end
  end

  protected

  def assert_transfered(getter, source, target, &block)
    val = source.send(getter)
    yield
    assert_equal val, target.send(getter)
  end

  def assert_changed(expression, &block)
    expression_evaluator = lambda { eval(expression, block.binding) }
    original_val = expression_evaluator.call
    yield
    assert original_val != expression_evaluator.call, "#{expression} is still #{original_val.inspect}"
  end

  def assert_unchanged(expression, &block)
    expression_evaluator = lambda { eval(expression, block.binding) }
    original_val = expression_evaluator.call
    yield
    new_val = expression_evaluator.call
    assert original_val == new_val, "#{expression} was #{original_val.inspect}, is now #{new_val.inspect}"
  end
end
