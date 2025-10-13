
import os
import sys
import json
import requests
from google import genai
from google.genai import types

# --- 1. 配置和 API 密钥 ---
# 从 GitHub Actions Secret 中获取 API 密钥
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    sys.exit("Error: GEMINI_API_KEY environment variable not set.")

JIRA_URL = os.getenv("JIRA_URL", "https://storehub.atlassian.net")
JIRA_USER = os.getenv("JIRA_USER")
JIRA_TOKEN = os.getenv("JIRA_TOKEN")

# --- 2. 结构化 JSON 定义 ---
# 定义我们期望 Gemini 返回的 JSON 结构
RISK_SCHEMA = types.Schema(
    type=types.Type.OBJECT,
    properties={
        "risk_level": types.Schema(
            type=types.Type.STRING,
            description="Overall risk level: High, Medium, or Low."
        ),
        "test_cases": types.Schema(
            type=types.Type.ARRAY,
            description="A list of specific test cases to validate the changes.",
            items=types.Schema(
                type=types.Type.OBJECT,
                properties={
                    "case_title": types.Schema(type=types.Type.STRING),
                    "description": types.Schema(type=types.Type.STRING),
                    "steps": types.Schema(type=types.Type.ARRAY, items=types.Schema(type=types.Type.STRING)),
                    "area": types.Schema(type=types.Type.STRING, description="The module or file area affected.")
                },
                required=["case_title", "description", "steps"]
            )
        ),
        "summary": types.Schema(
            type=types.Type.STRING,
            description="A brief summary of the QA analysis."
        )
    },
    required=["risk_level", "test_cases", "summary"]
)

# --- 3. Gemini 分析函数 ---
def analyze_code_with_gemini(code_diff):
    client = genai.Client(api_key=GEMINI_API_KEY)
    
    prompt = f"""
    You are an expert QA and Risk Analyst.
    Analyze the following code changes (diff) for potential bugs, security issues, and necessary test coverage.
    
    Code Diff:
    ---
    {code_diff}
    ---
    
    Please return a structured JSON object containing:
    1. A 'risk_level' (High, Medium, or Low).
    2. A 'summary' of your findings.
    3. A list of 'test_cases' (with title, detailed description, and steps) required to validate this change.
    """

    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=[prompt],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=RISK_SCHEMA,
            )
        )
        
        # 解析返回的 JSON 字符串
        return json.loads(response.text)
    
    except Exception as e:
        print(f"Gemini API Error: {e}")
        return None

# --- 4. JIRA 创建 Issue 函数 ---
def create_jira_issue(analysis_result, pr_title):
    if not JIRA_USER or not JIRA_TOKEN:
        print("JIRA credentials not set. Skipping JIRA issue creation.")
        return

    # 构建 JIRA 描述内容
    test_cases_text = ""
    for i, case in enumerate(analysis_result.get('test_cases', [])):
        steps = "\n".join([f"#* {step}" for step in case.get('steps', [])])
        test_cases_text += f"""
        *Case {i+1}: {case['case_title']}* (Area: {case.get('area', 'N/A')})
        {{panel:title=Description|borderStyle=dashed|borderColor=#ccc}}
        {case['description']}
        {{panel}}
        {{panel:title=Steps|borderStyle=dashed|borderColor=#ccc}}
        {steps}
        {{panel}}
        
        """
        
    jira_description = f"""
    h2. AI QA Analysis Report for PR: {pr_title}
    
    *Overall Risk Level:* *{analysis_result['risk_level']}*
    
    *AI Summary:*
    {{panel:title=Summary|borderStyle=solid|borderColor=#b80000}}
    {analysis_result['summary']}
    {{panel}}
    
    h3. Suggested Test Cases ({len(analysis_result.get('test_cases', []))} Total)
    {test_cases_text}
    """

    # JIRA API 请求体
    issue_data = {
        "fields": {
            # 请根据您的 JIRA 项目配置修改 'project' 和 'issuetype'
            "project": {"key": "YOUR_PROJECT_KEY"}, # 例如: "DEV"
            "summary": f"[AI QA Report] Risk {analysis_result['risk_level']} on PR: {pr_title}",
            "description": jira_description,
            "issuetype": {"name": "Task"} # 例如: "Task" 或 "Test Case"
        }
    }
    
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json"
    }
    auth = (JIRA_USER, JIRA_TOKEN)

    response = requests.post(
        f"{JIRA_URL}/rest/api/2/issue/",
        headers=headers,
        data=json.dumps(issue_data),
        auth=auth
    )

    if response.status_code == 201:
        print(f"Successfully created JIRA issue: {response.json()['key']}")
        return response.json()['key']
    else:
        print(f"Failed to create JIRA issue. Status code: {response.status_code}")
        print(f"Response: {response.text}")
        return None

# --- 5. 主执行逻辑 ---
if __name__ == "__main__":
    # 在 GitHub Actions 运行时，通过 git 命令获取本次 PR 的所有文件 diff
    # ⚠️ 注意: 这需要在 workflow 中设置 `fetch-depth: 0` 和获取基础分支名称
    try:
        # 假设我们只关心 PR event
        base_branch = os.getenv("GITHUB_BASE_REF")
        if not base_branch:
             print("Not a PR or GITHUB_BASE_REF is missing. Using HEAD for diff.")
             # 如果不是 PR，可以改为分析最近一次 commit 的 diff，但通常 PR 场景更常见。
             # 也可以直接退出 sys.exit("Not a Pull Request. Exiting.")
             
        # 获取 diff 的命令。对于 PR: git diff <base_branch> -- .
        # 简化演示，我们使用一个 placeholder。在实际 workflow 中，您需要执行 shell 命令来获取 diff。
        # code_diff = os.popen(f"git diff {base_branch} -- .").read()
        
        # 替换为从 Actions Environment Variable/Context 中获取的实际 diff
        # 实际操作中，您可能需要一个专门的 Action 或 Shell 脚本步骤来计算 diff 并将其设置为环境变量。
        # 例如，使用 `github.event.pull_request.diff_url` 或 `git diff`
        
        # 暂时使用一个硬编码的示例 diff 来测试 AI
        code_diff = """
        --- a/src/user_service.py
        +++ b/src/user_service.py
        @@ -10,6 +10,8 @@
         def get_user(user_id):
             if user_id <= 0:
        -        return None # Old bug
        +        # Fix: Return error message instead of None for invalid IDs
        +        return {"error": "Invalid user ID", "status": 400} 
             
             user_data = db.fetch(user_id)
             if not user_data:
        -        return None
        +        return {"error": "User not found", "status": 404} 
        
        """
        pr_title = os.getenv("GITHUB_PULL_REQUEST_TITLE", "Automated QA PR Analysis Test")

    except Exception as e:
        sys.exit(f"Failed to get code diff: {e}")


    print("--- Starting Gemini QA Analysis ---")
    analysis = analyze_code_with_gemini(code_diff)

    if analysis:
        print("\n--- Analysis Result (JSON) ---")
        print(json.dumps(analysis, indent=2))
        
        # 将结果推送到 JIRA
        print("\n--- Sending to JIRA ---")
        created_issue_key = create_jira_issue(analysis, pr_title)
        
        if created_issue_key:
            print(f"Workflow finished. JIRA Issue: {created_issue_key}")
            # 💡 提示：您还可以将 JIRA 链接作为评论添加到 GitHub PR 中
        
    else:
        sys.exit("Analysis failed. Exiting workflow.")
