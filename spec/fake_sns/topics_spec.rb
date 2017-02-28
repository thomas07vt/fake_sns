RSpec.describe "Topics" do

  it "rejects invalid characters in topic names" do
    expect {
      sns.create_topic(name: "dot.dot")
    }.to raise_error(Aws::SNS::Errors::InvalidParameterValue)
  end

  it "lists topics" do
    topic1_arn = sns.create_topic(name: "my-topic-1").topic_arn
    topic2_arn = sns.create_topic(name: "my-topic-2").topic_arn

    expect(sns.list_topics.topics.map(&:topic_arn)).to match_array [topic1_arn, topic2_arn]
  end

  it "deletes topics" do
    topic_arn = sns.create_topic(name: "my-topic").topic_arn
    expect(sns.list_topics.topics.map(&:topic_arn)).to eq [topic_arn]
    sns.delete_topic(topic_arn: topic_arn)
    expect(sns.list_topics.topics.map(&:topic_arn)).to eq []
  end

  it "can set and read attributes" do
    topic_arn = sns.create_topic(name: "my-topic").topic_arn
    expect(sns.get_topic_attributes(topic_arn: topic_arn).attributes["DisplayName"]).to eq nil

    sns.set_topic_attributes(topic_arn: topic_arn, attribute_name: "DisplayName", attribute_value: "the display name")
    expect(sns.get_topic_attributes(topic_arn: topic_arn).attributes["DisplayName"]).to eq "the display name"
  end

  it "creates a new topic" do
    topic_arn = sns.create_topic(name: "my-topic").topic_arn
    expect(topic_arn).to match(/arn:aws:sns:us-east-1:(\w+):my-topic/)

    new_topic_arn = sns.create_topic(name: "other-topic").topic_arn
    expect(new_topic_arn).not_to eq topic_arn

    existing_topic_arn = sns.create_topic(name: "my-topic").topic_arn
    expect(existing_topic_arn).to eq topic_arn
  end

  context 'setting the arn region' do
    before :all do
      @orig_region = ENV['fake_sns_region']
      ENV['fake_sns_region'] = 'us-west-1'
      $west_fake_sns = FakeSNS::TestIntegration.new(
        database:      ":memory:",
        sns_endpoint:  "localhost",
        sns_port:      9295,
      )
      $west_fake_sns.start
    end

    after :all do
      ENV['fake_sns_region'] = @orig_region
      $west_fake_sns.stop
    end

    it 'uses the ENV region var' do
      topic_arn = sns(9295).create_topic(name: "my-west-topic").topic_arn
      expect(topic_arn.include?('us-west-1')).to eq true
    end
  end

  context 'setting the arn account number' do
    before :all do
      @orig_acct = ENV['fake_sns_account']
      ENV['fake_sns_account'] = '0000001'
      $account_fake_sns = FakeSNS::TestIntegration.new(
        database:      ":memory:",
        sns_endpoint:  "localhost",
        sns_port:      9296,
      )
      $account_fake_sns.start
    end

    after :all do
      ENV['fake_sns_account'] = @orig_acct
      $account_fake_sns.stop
    end

    it 'uses the ENV region var' do
      topic_arn = sns(9296).create_topic(name: "my-account-topic").topic_arn
      expect(topic_arn.include?('0000001')).to eq true
    end
  end
end
