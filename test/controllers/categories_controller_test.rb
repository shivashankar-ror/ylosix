require 'test_helper'

class CategoriesControllerTest < ActionController::TestCase
  test 'should get index' do
    get :index, format: 'json'
    assert_response :success
  end

  test 'should get show' do
    object = categories(:digital_cameras)

    get :show, slug: object.slug
    assert_response :success

    get :show, id: object.id
    assert_response :success

    # TODO: check when id nil return 404 not found
  end

  test 'should should render 404 error' do
    object = categories(:digital_camera)

    assert_raises(ActiveRecord::RecordNotFound) do
      get :show, slug: object.slug
    end

    assert_raises(ActiveRecord::RecordNotFound) do
      get :show, id: object.id
    end
  end

  test 'should get tag' do
    tag = tags(:cameras)

    get :tags, slug_tags: tag.id
    assert_response :success
  end
end
