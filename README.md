# Resume Agent

Claude Code 커스텀 에이전트를 활용한 프로젝트 분석 및 이력서 작성 도구입니다.

## 기능

- **프로젝트 분석**: 코드베이스의 기술 스택, 구조, 주요 기능을 자동 분석
- **이력서용 설명 생성**: 분석 결과를 바탕으로 3가지 포맷(상세/간결/한줄)의 프로젝트 설명 생성
- **노션 게시**: 마크다운 콘텐츠를 노션 페이지에 자동 게시

## 설치

### 1. 저장소 클론

```bash
git clone https://github.com/YOUR_USERNAME/resume-agent.git
cd resume-agent
```

### 2. Notion API 설정

1. [Notion Integrations](https://www.notion.so/my-integrations)에서 새 통합 생성
2. Internal Integration Token 복사
3. `.mcp.json.example`을 `.mcp.json`으로 복사 후 토큰 입력:

```bash
cp .mcp.json.example .mcp.json
```

```json
{
  "mcpServers": {
    "notion": {
      "command": "npx",
      "args": ["-y", "@notionhq/notion-mcp-server"],
      "env": {
        "OPENAPI_MCP_HEADERS": "{\"Authorization\": \"Bearer YOUR_NOTION_API_TOKEN\", \"Notion-Version\": \"2025-09-03\"}"
      }
    }
  }
}
```

4. 노션에서 게시할 페이지에 통합 연결 (페이지 우상단 ... → 연결 → 생성한 통합 선택)

### 3. 스크립트 권한 설정

```bash
chmod +x scripts/notion-api.sh
```

### 4. 의존성 설치

```bash
npm install -g npx  # npx가 없는 경우
brew install jq     # macOS (jq가 없는 경우)
```

## 사용법

### Claude Code에서 에이전트 실행

```bash
# 프로젝트 분석 후 이력서용 설명 생성
claude "이 프로젝트 분석해서 이력서용으로 정리해줘"

# 프로젝트 분석만
claude "이 프로젝트 분석해줘"

# 노션에 게시
claude "이 내용을 노션에 게시해줘"
```

### Notion API 스크립트 직접 사용

```bash
# 페이지 검색
./scripts/notion-api.sh search "페이지 제목"

# 블록 추가
./scripts/notion-api.sh add <page_id> heading_2 "섹션 제목"
./scripts/notion-api.sh add <page_id> paragraph "본문 내용"
./scripts/notion-api.sh add <page_id> bulleted_list_item "리스트 항목"

# 마크다운 일괄 추가
./scripts/notion-api.sh add-markdown <page_id> "$MARKDOWN_CONTENT"

# 블록 조회
./scripts/notion-api.sh get <page_id>

# 블록 삭제
./scripts/notion-api.sh delete <block_id>
```

## 에이전트 구조

```
.claude/agents/
├── publish-orchestrator.md  # 메인 오케스트레이터
├── project-analyzer.md      # 프로젝트 분석 에이전트
├── resume-writer.md         # 이력서 작성 에이전트
└── notion-publisher.md      # 노션 게시 에이전트
```

## 지원하는 Notion 블록 타입

| 마크다운 | 블록 타입 |
|----------|-----------|
| `# 제목` | heading_1 |
| `## 제목` | heading_2 |
| `### 제목` | heading_3 |
| 일반 텍스트 | paragraph |
| `- 항목` | bulleted_list_item |
| `1. 항목` | numbered_list_item |
| `> 인용` | quote |
| `---` | divider |

## 제한사항

- **페이지 생성 불가**: Notion API 제한으로 페이지는 수동 생성 필요
- **블록 순서**: 맨 앞 삽입 미지원, 끝에만 추가 가능
- **코드 블록**: 현재 paragraph로 대체

## 라이선스

MIT License
