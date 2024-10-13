BATCH_SIZE = 1000

def create_file(batch_size = nil)
  File.open('file.txt', 'w') do |file|
    (1..(batch_size || BATCH_SIZE)).each do |_i|
      file.puts("#{Time.now.strftime('%Y-%m-%dT%H-%M-%S')},txn#{rand(1..999_999)},user#{rand(1..999_999)},#{rand(1..999_999)}.#{rand(1..99)}")
    end
  end
end

create_file
