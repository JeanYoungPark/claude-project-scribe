# Claude Project Scribe

Claude Code 커스텀 에이전트를 활용한 프로젝트 분석 및 문서화 도구입니다.
프로젝트를 분석하여 이력서용 설명을 생성하고, 노션에 자동으로 게시합니다.

## 기능

- **프로젝트 분석**: 코드베이스의 기술 스택, 구조, 주요 기능을 자동 분석
- **이력서용 설명 생성**: 분석 결과를 바탕으로 3가지 포맷(상세/간결/한줄)의 프로젝트 설명 생성
- **노션 게시**: 마크다운 콘텐츠를 노션 페이지에 자동 게시 (heading, list 등 모든 블록 타입 지원)
- **자동 태그 생성**: 기술 스택 기반으로 5-10개의 태그 자동 생성 및 노션 설정
- **커버 이미지 자동 설정**: Unsplash API를 통해 프로젝트에 맞는 커버 이미지 자동 검색 및 설정

## 설치

### 1. 저장소 클론

```bash
git clone https://github.com/JeanYoungPark/claude-project-scribe.git
cd claude-project-scribe
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

### 3. Unsplash API 설정 (선택 - 커버 이미지 기능 사용 시)

1. [Unsplash Developers](https://unsplash.com/developers)에서 계정 생성
2. 새 애플리케이션 등록 (Your Apps → New Application)
3. Access Key 복사
4. `.mcp.json`에 API 키 추가:

```json
{
  "mcpServers": {
    "notion": { ... }
  },
  "unsplashApiKey": "YOUR_UNSPLASH_ACCESS_KEY"
}
```

**주의**: 커버 이미지 기능을 사용하지 않으려면 이 단계를 건너뛰어도 됩니다. 태그와 본문 게시는 정상 작동합니다.

### 4. 스크립트 권한 설정

```bash
chmod +x scripts/notion-api.sh
chmod +x scripts/unsplash-api.sh
```

### 5. 의존성 설치

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
./scripts/notion-api.sh add <page_id> code "const x = 1;" javascript
./scripts/notion-api.sh add <page_id> quote "중요한 인용문"
./scripts/notion-api.sh add <page_id> callout "💡 유용한 팁"

# 커버 이미지 설정
./scripts/notion-api.sh cover <page_id> "https://images.unsplash.com/..."

# 마크다운 일괄 추가
./scripts/notion-api.sh add-markdown <page_id> "$MARKDOWN_CONTENT"

# 블록 조회
./scripts/notion-api.sh get <page_id>

# 블록 삭제
./scripts/notion-api.sh delete <block_id>
```

### Unsplash API 스크립트 사용

```bash
# 키워드로 이미지 검색
./scripts/unsplash-api.sh search "react typescript" landscape 5

# 랜덤 이미지 URL 가져오기
./scripts/unsplash-api.sh random-url "education game"

# 프로젝트 태그로 커버 이미지 URL 가져오기
./scripts/unsplash-api.sh cover "react,typescript,game" landscape
```

## 에이전트 구조

```
.claude/agents/
├── publish-orchestrator.md  # 메인 오케스트레이터
├── project-analyzer.md      # 프로젝트 분석 에이전트
├── resume-writer.md         # 이력서 작성 에이전트
├── notion-publisher.md      # 노션 게시 에이전트
└── cover-image-finder.md    # 커버 이미지 검색 에이전트
```

### 에이전트 역할

- **publish-orchestrator**: 전체 워크플로우 조율 (분석 → 작성 → 게시)
- **project-analyzer**: 코드베이스 분석 및 기술 스택 추출, 태그/커버 키워드 생성
- **resume-writer**: 이력서용 프로젝트 설명 작성 (3가지 포맷)
- **notion-publisher**: 노션 페이지 게시 및 태그/커버 이미지 설정
- **cover-image-finder**: Unsplash API로 프로젝트에 맞는 커버 이미지 검색

## 지원하는 Notion 블록 타입

| 마크다운 | 블록 타입 | 예시 |
|----------|-----------|------|
| `# 제목` | heading_1 | 대제목 |
| `## 제목` | heading_2 | 섹션 제목 |
| `### 제목` | heading_3 | 소제목 |
| 일반 텍스트 | paragraph | 본문 |
| `- 항목` | bulleted_list_item | 불릿 목록 |
| `1. 항목` | numbered_list_item | 번호 목록 |
| `> 인용` | quote | 인용문 |
| N/A | callout | 강조 박스 |
| ` ```언어` | code | 코드 블록 |
| `---` | divider | 구분선 |

## 제한사항

- **페이지 생성 불가**: Notion API 제한으로 페이지는 수동 생성 필요
- **블록 순서**: 맨 앞 삽입 미지원, 끝에만 추가 가능
- **Unsplash API 제한**: 무료 플랜은 시간당 50 요청 제한
- **커버 이미지**: Unsplash API 키가 없으면 커버 이미지 설정 건너뜀

## 라이선스

MIT License
