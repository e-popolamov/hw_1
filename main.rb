# frozen_string_literal: true

require 'tempfile'

DEFAULT_CHUNK_SIZE = 300
DEFAULT_INPUT_FILE_NAME = 'file.txt'
SORTED_FILE_NAME = 'sorted'
CHUNK_FILE_NAME = 'chunk'
RESULT_FILE_NAME = 'sorted.txt'


class Row
  attr_reader :date, :txn_id, :user_id, :amount

  def initialize(date, txn_id, user_id, amount)
    @date = date
    @txn_id = txn_id
    @user_id = user_id
    @amount = amount.to_f
  end

  def to_s
    "#{date}, #{txn_id}, #{user_id}, #{amount}"
  end
end


def merge_sort(files)
  return files.first if files.size == 1

  mid = files.size / 2
  left = merge_sort(files[0...mid])
  right = merge_sort(files[mid..-1])

  merge(left, right)
end

def next_data(merged_file, line, line_io)
  merged_file.puts(line)
  line_io.gets
end

def merge(left_file, right_file)
  merged_file = Tempfile.new(SORTED_FILE_NAME)

  left_io = File.open(left_file, 'r')
  right_io = File.open(right_file, 'r')

  left_line = left_io.gets
  right_line = right_io.gets

  while left_line && right_line
    left_transaction = parse_line(left_line)
    right_transaction = parse_line(right_line)

    if left_transaction.amount >= right_transaction.amount
      left_line = next_data(merged_file, left_line, left_io)
    else
      right_line = next_data(merged_file, right_line, right_io)
    end
  end

  left_line = next_data(merged_file, left_line, left_io) while left_line
  right_line = next_data(merged_file, right_line, right_io) while right_line

  left_io.close
  right_io.close
  merged_file.rewind
  merged_file
end

def parse_line(line)
  Row.new(*line.strip.split(','))
end

class Array
  def sort_amount
    each_with_index do |_, index|
      (index + 1).upto(size - 1) do |i|
        self[index], self[i] = self[i], self[index] if self[index].amount < self[i].amount
      end
    end
  end
end


def write_temp_file(batch, chunk_files)
  sorted_chunk = batch.map { |line| parse_line(line) }.sort_amount
  chunk_file = File.open("#{CHUNK_FILE_NAME}#{rand(100)}", 'w')
  sorted_chunk.each { |line| chunk_file.puts(line) }
  chunk_files << chunk_file.path
  chunk_file.close
  batch.clear
end


def write_result_file(sorted_file)
  File.open(RESULT_FILE_NAME, 'w') { |file| sorted_file.each_line { |line| file.puts(line) } }
end

def process_file(chunk_files = [])
  File.open(DEFAULT_INPUT_FILE_NAME, 'r') do |file|
    chunk = []
    file.each_line do |line|
      chunk << line.dup
      write_temp_file(chunk, chunk_files) if chunk.size >= DEFAULT_CHUNK_SIZE
    end
    write_temp_file(chunk, chunk_files) if chunk.any?
  end
  write_result_file(merge_sort(chunk_files))
  chunk_files.map { |file| File.delete(file) if File.exist?(file) }
end

process_file