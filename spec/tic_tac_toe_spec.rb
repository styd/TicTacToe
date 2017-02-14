require "spec_helper"

RSpec.describe TicTacToe do
  it "has a version number" do
    expect(TicTacToe::VERSION).not_to be nil
  end
end
