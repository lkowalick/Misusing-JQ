require 'minitest/autorun'
require 'json'

COMMAND = %Q(
echo '"%{score_string}"' | jq '
{"A": "B", "B": "A"} as $other |
split("") |
reduce .[] as $char
(
  { "A": { "score": 0, "games": 0 }, "B": { "score": 0, "games": 0 } };
  if
    .[$char].score >= 3 and .[$char].score >= .[$other[$char]].score + 1
  then
    .["A"].score = 0 | .["B"].score = 0 | .[$char].games |= . + 1
  else
    .[$char].score |= .+1
  end
) |
.A.score as $a |
.B.score as $b |
["love", "15", "30", "40"] as $pp_lookup |
if
  $a == $b and $a >= 3
then
  .A.score = "deuce" | .B.score = "deuce"
elif
  $a > $b and $a >= 4
then
  .A.score = "advantage" | .B.score =""
elif
  $b > $a and $b >= 4
then
  .A.score = "" | .B.score = "advantage"
else
  .A.score = $pp_lookup[$a] | .B.score = $pp_lookup[$b]
end
'
)

def score(string)
  JSON.parse(`#{sprintf(COMMAND, { score_string: string })}`)
end

Class.new(MiniTest::Test) do
  def test_score
    assert_equal(score("AAABBB")["A"]["score"], "deuce")
    assert_equal(score("AAABBB")["B"]["score"], "deuce")
    assert_equal(score("")["A"]["score"], "love")
    assert_equal(score("")["B"]["score"], "love")
  end

  def test_game_score
    assert_equal(score("AAAABB")["A"]["score"], "love")
    assert_equal(score("AAAABB")["B"]["score"], "30")
    assert_equal(score("AAAABB")["A"]["games"], 1)
    assert_equal(score("AAAABB")["B"]["games"], 0)
    assert_equal(score("BBAAAA")["A"]["score"], "love")
    assert_equal(score("BBAAAA")["B"]["score"], "love")
    assert_equal(score("BBAAAA")["A"]["games"], 1)
    assert_equal(score("BBAAAA")["B"]["games"], 0)
  end

  def test_deuce_score
    assert_equal(score("AAABBB")["A"]["score"], "deuce")
    assert_equal(score("AAABBB")["A"]["score"], "deuce")
    assert_equal(score("AAABBBA")["A"]["score"], "advantage")
    assert_equal(score("AAABBBA")["B"]["score"], "")
    assert_equal(score("AAABBBAB")["B"]["score"], "deuce")
    assert_equal(score("AAABBBAB")["A"]["score"], "deuce")
    assert_equal(score("AAABBBAA")["A"]["score"], "love")
    assert_equal(score("AAABBBAA")["B"]["score"], "love")
    assert_equal(score("AAABBBAA")["A"]["games"], 1)
  end
end
