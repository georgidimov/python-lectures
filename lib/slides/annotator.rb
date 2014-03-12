class Annotator
  def initialize(code)
    @code = code
  end

  def execute
    marked_code, mark_count = add_marks @code
    if mark_count > 0
      collecting = add_mark_collecting marked_code
      values     = run_code collecting
      replace_marks marked, values
    else
      marked_code
    end
  end

  private

  def add_marks(code)
    counter = 0
    marked = code.gsub(/# =>$/) do |mark|
      counter += 1
      "# {#{counter}}"
    end
    [marked, counter]
  end

  def add_mark_collecting(code)
    code = code.gsub(/\A/, <<-HEADER).gsub(/\z/, <<-FOOTER)
import json
__marks__ = {}
__dumps__ = repr

HEADER

print(json.dumps(__marks__))
FOOTER
    code = code.gsub(/^(\s*)(.*?)\s*# {(\d+)}$/) { <<-END }
#$1try: __marks__[#$3] = __dumps__(#$2)
#$1except Exception as e: __marks__[#$3] = __dumps__(e)
    END
    code
  end

  def run_code(code)
    puts "Running code"
    Open3.popen3('python3') do |stdin, stdout, stderr|
      stdin.puts code
      stdin.close

      puts stderr.read
      puts stdout.read

      JSON.parse stdout.read
    end
  end

  def replace_marks(marked, values)
    marked.gsub(/# {(\d+)}$/) { "# #{values[$1]}" }
  end
end
