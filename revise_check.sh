Last login: Mon Jun 15 12:50:56 on ttys008

~
❯ curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [{"role": "user", "content": "Write SELECT 1"}],
    "max_tokens": 100
  }'

{"id":"chatcmpl-299cd6a7461f4412b2eb5c9f61c293d3","object":"chat.completion","created":1781528017,"model":"Qwen/Qwen3-30B-A3B-Instruct-2507","choices":[{"index":0,"message":{"role":"assistant","content":"```sql\nSELECT 1;\n```","refusal":null,"annotations":null,"audio":null,"function_call":null,"tool_calls":[],"reasoning_content":null},"logprobs":null,"finish_reason":"stop","stop_reason":null,"token_ids":null}],"service_tier":null,"system_fingerprint":null,"usage":{"prompt_tokens":12,"total_tokens":21,"completion_tokens":9,"prompt_tokens_details":null},"prompt_logprobs":null,"prompt_token_ids":null,"kv_transfer_params":null}
~
❯ curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [{"role": "user", "content": "Write SELECT 1"}],
    "max_tokens": 100
  }'
{"id":"chatcmpl-187b202775cf49fcafa15f0c33cc5c8f","object":"chat.completion","created":1781528214,"model":"Qwen/Qwen3-30B-A3B-Instruct-2507","choices":[{"index":0,"message":{"role":"assistant","content":"```sql\nSELECT 1;\n```","refusal":null,"annotations":null,"audio":null,"function_call":null,"tool_calls":[],"reasoning_content":null},"logprobs":null,"finish_reason":"stop","stop_reason":null,"token_ids":null}],"service_tier":null,"system_fingerprint":null,"usage":{"prompt_tokens":12,"total_tokens":21,"completion_tokens":9,"prompt_tokens_details":null},"prompt_logprobs":null,"prompt_token_ids":null,"kv_transfer_params":null}
~
❯ curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [
      {"role": "system", "content": "You are a SQL expert. Write a SQLite query answering the question. Return only the SQL inside a ```sql block."},
      {"role": "user", "content": "How many male clients in '\''Hl.m. Praha'\'' district? DB: financial"}
    ],
    "max_tokens": 200
  }' | python3 -m json.tool

{
    "id": "chatcmpl-c933a5eaae204d77850b5272566431f4",
    "object": "chat.completion",
    "created": 1781528850,
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "```sql\nSELECT COUNT(*) \nFROM clients \nWHERE gender = 'male' \n  AND district = 'Hl.m. Praha';\n```",
                "refusal": null,
                "annotations": null,
                "audio": null,
                "function_call": null,
                "tool_calls": [],
                "reasoning_content": null
            },
            "logprobs": null,
            "finish_reason": "stop",
            "stop_reason": null,
            "token_ids": null
        }
    ],
    "service_tier": null,
    "system_fingerprint": null,
    "usage": {
        "prompt_tokens": 55,
        "total_tokens": 86,
        "completion_tokens": 31,
        "prompt_tokens_details": null
    },
    "prompt_logprobs": null,
    "prompt_token_ids": null,
    "kv_transfer_params": null
}

~
❯ curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [
      {"role": "system", "content": "You are a SQL expert. Write a SQLite query answering the question. Return only the SQL inside a ```sql block."},
      {"role": "user", "content": "How many users received commentator badges in 2014? DB: codebase_community (tables: badges(Id, UserId, Name, Date))"}
    ],
    "max_tokens": 200
  }' | python3 -m json.tool
{
    "id": "chatcmpl-a01f16407a464ba4829d22ae4824a066",
    "object": "chat.completion",
    "created": 1781528925,
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "```sql\nSELECT COUNT(DISTINCT UserId) \nFROM badges \nWHERE Name = 'Commentator' \n  AND Date >= '2014-01-01' \n  AND Date < '2015-01-01';\n```",
                "refusal": null,
                "annotations": null,
                "audio": null,
                "function_call": null,
                "tool_calls": [],
                "reasoning_content": null
            },
            "logprobs": null,
            "finish_reason": "stop",
            "stop_reason": null,
            "token_ids": null
        }
    ],
    "service_tier": null,
    "system_fingerprint": null,
    "usage": {
        "prompt_tokens": 67,
        "total_tokens": 124,
        "completion_tokens": 57,
        "prompt_tokens_details": null
    },
    "prompt_logprobs": null,
    "prompt_token_ids": null,
    "kv_transfer_params": null
}

~
❯ curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [
      {"role": "system", "content": "You are a SQL expert. Write a SQLite query answering the question. Return only the SQL inside a ```sql block."},
      {"role": "user", "content": "List down Ajax'\''s superpowers. DB: superhero (tables: superhero, hero_power, superpower)"}
    ],
    "max_tokens": 200
  }' | python3 -m json.tool

{
    "id": "chatcmpl-93c4421c294c41d9a702fcc33dfa1cae",
    "object": "chat.completion",
    "created": 1781528955,
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "```sql\nSELECT sp.power_name\nFROM superhero s\nJOIN hero_power hp ON s.hero_id = hp.hero_id\nJOIN superpower sp ON hp.power_id = sp.power_id\nWHERE s.hero_name = 'Ajax';\n```",
                "refusal": null,
                "annotations": null,
                "audio": null,
                "function_call": null,
                "tool_calls": [],
                "reasoning_content": null
            },
            "logprobs": null,
            "finish_reason": "stop",
            "stop_reason": null,
            "token_ids": null
        }
    ],
    "service_tier": null,
    "system_fingerprint": null,
    "usage": {
        "prompt_tokens": 58,
        "total_tokens": 106,
        "completion_tokens": 48,
        "prompt_tokens_details": null
    },
    "prompt_logprobs": null,
    "prompt_token_ids": null,
    "kv_transfer_params": null
}

~
❯
~
❯ curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [
      {"role": "system", "content": "You are a SQL expert. Write a SQLite query answering the question. Return only the SQL inside a ```sql block."},
      {"role": "user", "content": "Calculate the percentage of carcinogenic molecules which contain the Chlorine element. DB: toxicology (tables: atom(atom_id, molecule_id, element), molecule(molecule_id, label))"}
    ],
    "max_tokens": 200
  }' | python3 -m json.tool

{
    "id": "chatcmpl-6d16b2f87a8a4ca49d7602e2505b7273",
    "object": "chat.completion",
    "created": 1781529011,
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "```sql\nSELECT \n    (COUNT(CASE WHEN a.element = 'Cl' THEN 1 END) * 100.0 / COUNT(*)) AS percentage_chlorine_in_carcinogenic\nFROM \n    molecule m\n    JOIN atom a ON m.molecule_id = a.molecule_id\nWHERE \n    m.label = 'carcinogenic';\n```",
                "refusal": null,
                "annotations": null,
                "audio": null,
                "function_call": null,
                "tool_calls": [],
                "reasoning_content": null
            },
            "logprobs": null,
            "finish_reason": "stop",
            "stop_reason": null,
            "token_ids": null
        }
    ],
    "service_tier": null,
    "system_fingerprint": null,
    "usage": {
        "prompt_tokens": 74,
        "total_tokens": 152,
        "completion_tokens": 78,
        "prompt_tokens_details": null
    },
    "prompt_logprobs": null,
    "prompt_token_ids": null,
    "kv_transfer_params": null
}

~
❯
~
❯ curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [
      {"role": "system", "content": "You are a SQL expert. Write a SQLite query answering the question. Return only the SQL inside a ```sql block."},
      {"role": "user", "content": "Which active district has the highest average score in Reading? DB: california_schools (tables: schools(CDSCode, District, StatusType), satscores(cds, AvgScrRead))"}
    ],
    "max_tokens": 200
  }' | python3 -m json.tool

{
    "id": "chatcmpl-36e941bc96414830827bda0a350a56ec",
    "object": "chat.completion",
    "created": 1781529041,
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "```sql\nSELECT s.District\nFROM schools s\nJOIN satscores ss ON s.CDSCode = ss.cds\nWHERE s.StatusType = 'Active'\nGROUP BY s.District\nORDER BY AVG(ss.AvgScrRead) DESC\nLIMIT 1;\n```",
                "refusal": null,
                "annotations": null,
                "audio": null,
                "function_call": null,
                "tool_calls": [],
                "reasoning_content": null
            },
            "logprobs": null,
            "finish_reason": "stop",
            "stop_reason": null,
            "token_ids": null
        }
    ],
    "service_tier": null,
    "system_fingerprint": null,
    "usage": {
        "prompt_tokens": 76,
        "total_tokens": 134,
        "completion_tokens": 58,
        "prompt_tokens_details": null
    },
    "prompt_logprobs": null,
    "prompt_token_ids": null,
    "kv_transfer_params": null
}

~
❯
~
❯ curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [
      {"role": "system", "content": "You are a SQL expert. Write a SQLite query answering the question. Return only the SQL inside a ```sql block."},
      {"role": "user", "content": "Calculate the difference of the total amount spent in all events by the Student_Club in year 2019 and 2020. DB: student_club (tables: event(event_id, event_date), budget(link_to_event, spent))"}
    ],
    "max_tokens": 200
  }' | python3 -m json.tool

{
    "id": "chatcmpl-dbf0b9b6e6c748b8aa077cd5ecc90a24",
    "object": "chat.completion",
    "created": 1781529063,
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "```sql\nSELECT \n    (SELECT SUM(b.spent) \n     FROM budget b \n     JOIN event e ON b.link_to_event = e.event_id \n     WHERE strftime('%Y', e.event_date) = '2019') -\n    (SELECT SUM(b.spent) \n     FROM budget b \n     JOIN event e ON b.link_to_event = e.event_id \n     WHERE strftime('%Y', e.event_date) = '2020') AS amount_difference;\n```",
                "refusal": null,
                "annotations": null,
                "audio": null,
                "function_call": null,
                "tool_calls": [],
                "reasoning_content": null
            },
            "logprobs": null,
            "finish_reason": "stop",
            "stop_reason": null,
            "token_ids": null
        }
    ],
    "service_tier": null,
    "system_fingerprint": null,
    "usage": {
        "prompt_tokens": 89,
        "total_tokens": 191,
        "completion_tokens": 102,
        "prompt_tokens_details": null
    },
    "prompt_logprobs": null,
    "prompt_token_ids": null,
    "kv_transfer_params": null
}

~
❯
~
❯ curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "messages": [
      {"role": "system", "content": "You are a SQL expert. Write a SQLite query answering the question. Return only the SQL inside a ```sql block."},
      {"role": "user", "content": "What is the average fastest lap time in seconds for Lewis Hamilton in all Formula 1 races? DB: formula_1 (tables: drivers(driverId, forename, surname), results(driverId, fastestLapTime))"}
    ],
    "max_tokens": 300
  }' | python3 -m json.tool

{
    "id": "chatcmpl-2cbfaea28ed84001b6118a4ca749d679",
    "object": "chat.completion",
    "created": 1781529091,
    "model": "Qwen/Qwen3-30B-A3B-Instruct-2507",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "```sql\nSELECT AVG(r.fastestLapTime) AS average_fastest_lap_time\nFROM results r\nJOIN drivers d ON r.driverId = d.driverId\nWHERE d.forename = 'Lewis' AND d.surname = 'Hamilton';\n```",
                "refusal": null,
                "annotations": null,
                "audio": null,
                "function_call": null,
                "tool_calls": [],
                "reasoning_content": null
            },
            "logprobs": null,
            "finish_reason": "stop",
            "stop_reason": null,
            "token_ids": null
        }
    ],
    "service_tier": null,
    "system_fingerprint": null,
    "usage": {
        "prompt_tokens": 82,
        "total_tokens": 135,
        "completion_tokens": 53,
        "prompt_tokens_details": null
    },
    "prompt_logprobs": null,
    "prompt_token_ids": null,
    "kv_transfer_params": null
}

~
❯

~
❯

~
❯
~
❯ curl -X POST http://localhost:8001/answer \
  -H "Content-Type: application/json" \
  -d '{"question": "List Ajax superpowers.", "db": "superhero"}'
{"sql":"It seems like your message might be incomplete. Could you please clarify or provide more details about what you're asking? Whether it's a question, a request for help, or something else, I'm here to assist!","rows":null,"iterations":3,"ok":false,"error":"OperationalError: near \"It\": syntax error","history":[{"node":"generate_sql","sql":"It seems like your message might be incomplete. Could you please clarify or provide more details about what you're asking? Whether it's a question, a request for help, or something else, I'm here to assist!"},{"node":"revise","sql":"It seems like your message might be incomplete. Could you please clarify or provide more details about what you're asking? Whether it's a question, a request for help, or something else, I'm here to assist!"},{"node":"revise","sql":"It seems like your message might be incomplete. Could you please clarify or provide more details about what you're asking? Whether it's a question, a request for help, or something else, I'm here to assist!"}]}
~
❯ curl -X POST http://localhost:8001/answer \
  -H "Content-Type: application/json" \
  -d '{"question": "List Ajax superpowers.", "db": "superhero"}'
{"sql":"SELECT sp.power_name\nFROM superhero s\nJOIN hero_power hp ON s.id = hp.hero_id\nJOIN superpower sp ON hp.power_id = sp.id\nWHERE s.superhero_name = 'Ajax';","rows":[["Agility"],["Super Strength"],["Super Speed"],["Heat Generation"],["Power Suit"]],"iterations":1,"ok":true,"error":null,"history":[{"node":"generate_sql","sql":"SELECT sp.power_name\nFROM superhero s\nJOIN hero_power hp ON s.id = hp.hero_id\nJOIN superpower sp ON hp.power_id = sp.id\nWHERE s.superhero_name = 'Ajax';"}]}
~
❯ #!/bin/bash
set -euo pipefail

# Configuration
URL="http://localhost:8001/answer"
LOG_FILE="phase3.log"

# Clear or initialize the log file
echo "=== Phase 3 Evaluation Run: $(date) ===" > "$LOG_FILE"

# Function to execute and log a curl request cleanly
run_request() {
    local num=$1
    local name=$2
    local data=$3

    echo -e "\n----------------------------------------" >> "$LOG_FILE"
    echo "Request #${num}: ${name}" >> "$LOG_FILE"
    echo "Payload: ${data}" >> "$LOG_FILE"
    echo -e "----------------------------------------" >> "$LOG_FILE"
    echo "Response:" >> "$LOG_FILE"

    # Execute curl, capture response, print to log file, and ensure a trailing newline
    curl -s -X POST "$URL" \
      -H "Content-Type: application/json" \
      -d "$data" >> "$LOG_FILE"

    echo "" >> "$LOG_FILE"
}

echo "Starting evaluation. Output will be written to ${LOG_FILE}..."

# 1. Exact timestamp format — codebase_community
run_request "1" "Exact timestamp format (codebase_community)" \
  '{"question": "User No.23853 gave a comment to a post at 9:08:18 on 2013/7/12, was that post well-finished?", "db": "codebase_community"}'

# 2. Cryptic column name with no description — financial
run_request "2" "Cryptic column name (financial)" \
  '{"question": "What is the average number of crimes committed in 1995 in regions where the number exceeds 4000 and the region has accounts that are opened starting from the year 1997?", "db": "financial"}'

# 3. NULL vs zero for missing data — superhero
run_request "3" "NULL vs zero for missing data (superhero)" \
  '{"question": "In superheroes with missing weight data, calculate the difference between the number of superheroes with blue eyes and no eye color.", "db": "superhero"}'

# 4. Sex-based thresholds + correlated subquery — thrombosis_prediction
run_request "4" "Sex-based thresholds + correlated subquery (thrombosis_prediction)" \
  '{"question": "For all patients with normal uric acid (UA), what is the average UA index based on their latest laboratory examination result?", "db": "thrombosis_prediction"}'

# 5. Wrong join key — codebase_community
run_request "5" "Wrong join key (codebase_community)" \
  '{"question": "Mention the display name and location of the user who owned the excerpt post with hypothesis-testing tag.", "db": "codebase_community"}'

echo "All requests finished. Check ${LOG_FILE} for results."















