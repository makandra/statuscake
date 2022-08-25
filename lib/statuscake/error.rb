class StatusCake::Error < StandardError
  attr_reader :json

  def initialize(json)
    @json = json
    super(json['errors'])
  end

  def err_no
    json['errors']
  end
end
