class TestLINQ < Test::Unit::TestCase
  sub_test_case("array") do
    test("where") do
      scores = [97, 92, 81, 60]
      query = TableQuery.from(:score, in: scores)
                        .where { score > 80 }
                        .select { score }
      assert_equal([97, 92, 81],
                   query.to_a)
    end

    test("group") do
      vegetables = ["carrots", "cabbage", "broccoli", "beans", "barley"]
      query = TableQuery.from(:vegetable, in: vegetables)
                        .group_by { vegetable[0] }
      assert_equal({"c" => ["carrots", "cabbage"], "b" => ["broccoli", "beans", "barley"]},
                   query.to_h)
    end
  end

  sub_test_case("struct") do
    test("struct") do
      student_class = Struct.new(:first_name, :last_name, :id, :year, :exam_scores)
      students = [
        student_class.new("Terry",    "Adams",       120, 2, [99, 82, 81, 79]),
        student_class.new("Fadi",     "Fakhouri",    116, 3, [99, 86, 90, 94]),
        student_class.new("Hanying",  "Feng",        117, 1, [93, 92, 80, 87]),
        student_class.new("Cesar",    "Garcia",      114, 4, [97, 89, 85, 82]),
        student_class.new("Debra",    "Garcia",      115, 3, [35, 72, 91, 70]),
        student_class.new("Hugo",     "Garcia",      118, 2, [92, 90, 83, 78]),
        student_class.new("Sven",     "Mortensen",   113, 1, [88, 94, 65, 91]),
        student_class.new("Claire",   "O'Donnell",   112, 4, [75, 84, 91, 39]),
        student_class.new("Svetlana", "Omelchenko",  111, 2, [97, 92, 81, 60]),
        student_class.new("Lance",    "Tucker",      119, 3, [68, 79, 88, 92]),
        student_class.new("Michael",  "Tucker",      122, 1, [94, 92, 91, 91]),
        student_class.new("Eugene",   "Zabokritski", 121, 4, [96, 85, 91, 60])
      ]

      high_scores_query = ->(exam, score) do
        TableQuery.from(:student, in: students)
          .where { student.exam_scores[exam] > score }
          .select { {name: student.first_name, score: student.exam_scores[exam] } }
      end

      result = high_scores_query.(1, 90).map {|item| "#{item[:name]}:#{item[:score]}" }.join(" ")
      assert_equal("Hanying:92 Sven:94 Svetlana:92 Michael:92", result)
    end
  end
end
