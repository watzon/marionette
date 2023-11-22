require "../spec_helper"

include Marionette

Spectator.describe Marionette::ActionBuilder do
  let(:session) { described_class.new(TEST_SESSION) }
  let(:w3c_session) { described_class.new(W3C_TEST_SESSION) }

  # Reset actions after each run
  after_each { session.reset_actions }

  describe "#initialize" do
    it "should set default instance variables" do
      expect(session.session).to eq(TEST_SESSION)
      expect(session.w3c_key_actions).to be_empty
      expect(session.w3c_pointer_actions).to be_empty
      expect(session.actions).to be_empty
    end
  end

  describe "#w3c_action" do
    it "should add a new key action" do
      action = Action::KeyUp.new("a")
      session.w3c_action(action)

      expect(session.w3c_key_actions).to contain_exactly(action)

      expect(session.w3c_pointer_actions.size).to eq(1)
      expect(session.w3c_pointer_actions.first).to be_a(Action::PointerPause)
    end

    it "should add a new pointer action" do
      action = Action::PointerUp.new(:left, 0.seconds)
      session.w3c_action(action)

      expect(session.w3c_pointer_actions).to contain_exactly(action)

      expect(session.w3c_key_actions.size).to eq(1)
      expect(session.w3c_key_actions.first).to be_a(Action::KeyPause)
    end
  end

  describe "#action" do
    it "should add a new non w3c action" do
      action = Action::KeyUp.new("a")
      session.action("SendKeysToActiveElement", action)

      expect(session.actions).to contain_exactly({"SendKeysToActiveElement", action})
    end

    it "should raise an UnknownCommand exception for a non-existent command" do
      action = Action::KeyUp.new("a")
      expect { session.action("ThisCommandDoesNotExist", action) }.to raise_error(Error::UnknownCommand)
    end
  end

  describe "#create_key_up" do
    it "should create a new KeyUp action" do
      key_up = session.create_key_up(Key::Enter)
      expect(key_up).to be_a(Action::KeyUp)
      expect(key_up.value).to eq(Key::Enter.to_s)
    end
  end

  describe "#create_key_down" do
    it "should create a new KeyDown action" do
      key_down = session.create_key_down(Key::Enter)
      expect(key_down).to be_a(Action::KeyDown)
      expect(key_down.value).to eq(Key::Enter.to_s)
    end
  end

  describe "#create_mouse_down" do
    it "should create a new PointerDown action" do
      mouse_down = session.create_mouse_down(:left, 0.seconds)
      expect(mouse_down).to be_a(Action::PointerDown)
      expect(mouse_down.button).to eq(MouseButton::Left)
      expect(mouse_down.click_duration).to eq(0.seconds)
    end
  end

  describe "#create_mouse_up" do
    it "should create a new PointerDown action" do
      mouse_up = session.create_mouse_up(:left, 0.seconds)
      expect(mouse_up).to be_a(Action::PointerUp)
      expect(mouse_up.button).to eq(MouseButton::Left)
      expect(mouse_up.click_duration).to eq(0.seconds)
    end
  end
end
