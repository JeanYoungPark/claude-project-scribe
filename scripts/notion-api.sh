#!/bin/bash

# Notion API Helper Script
# MCP 도구의 블록 타입 제한을 우회하여 heading 등 모든 블록 타입 지원

# 설정 파일에서 토큰 읽기
CONFIG_FILE="$(dirname "$0")/../.mcp.json"
NOTION_TOKEN=$(cat "$CONFIG_FILE" | jq -r '.mcpServers.notion.env.OPENAPI_MCP_HEADERS' | jq -r '.Authorization' | sed 's/Bearer //')
NOTION_VERSION="2022-06-28"

# 공통 헤더
AUTH_HEADER="Authorization: Bearer $NOTION_TOKEN"
VERSION_HEADER="Notion-Version: $NOTION_VERSION"
CONTENT_HEADER="Content-Type: application/json"

# 페이지에 블록 추가
# Usage: add_block <page_id> <block_type> <content> [after_block_id]
add_block() {
    local page_id="$1"
    local block_type="$2"
    local content="$3"
    local after_id="$4"

    local after_param=""
    if [ -n "$after_id" ]; then
        after_param="\"after\": \"$after_id\","
    fi

    local block_json=""
    case "$block_type" in
        heading_1|heading_2|heading_3)
            block_json="{\"object\": \"block\", \"type\": \"$block_type\", \"$block_type\": {\"rich_text\": [{\"type\": \"text\", \"text\": {\"content\": \"$content\"}}]}}"
            ;;
        paragraph)
            block_json="{\"object\": \"block\", \"type\": \"paragraph\", \"paragraph\": {\"rich_text\": [{\"type\": \"text\", \"text\": {\"content\": \"$content\"}}]}}"
            ;;
        bulleted_list_item)
            block_json="{\"object\": \"block\", \"type\": \"bulleted_list_item\", \"bulleted_list_item\": {\"rich_text\": [{\"type\": \"text\", \"text\": {\"content\": \"$content\"}}]}}"
            ;;
        numbered_list_item)
            block_json="{\"object\": \"block\", \"type\": \"numbered_list_item\", \"numbered_list_item\": {\"rich_text\": [{\"type\": \"text\", \"text\": {\"content\": \"$content\"}}]}}"
            ;;
        quote)
            block_json="{\"object\": \"block\", \"type\": \"quote\", \"quote\": {\"rich_text\": [{\"type\": \"text\", \"text\": {\"content\": \"$content\"}}]}}"
            ;;
        callout)
            block_json="{\"object\": \"block\", \"type\": \"callout\", \"callout\": {\"rich_text\": [{\"type\": \"text\", \"text\": {\"content\": \"$content\"}}]}}"
            ;;
        divider)
            block_json="{\"object\": \"block\", \"type\": \"divider\", \"divider\": {}}"
            ;;
        *)
            echo "Unsupported block type: $block_type" >&2
            return 1
            ;;
    esac

    curl -s -X PATCH "https://api.notion.com/v1/blocks/$page_id/children" \
        -H "$AUTH_HEADER" \
        -H "$VERSION_HEADER" \
        -H "$CONTENT_HEADER" \
        -d "{$after_param \"children\": [$block_json]}"
}

# 여러 블록 한번에 추가
# Usage: add_blocks <page_id> <json_file> [after_block_id]
add_blocks() {
    local page_id="$1"
    local json_file="$2"
    local after_id="$3"

    local after_param=""
    if [ -n "$after_id" ]; then
        after_param="\"after\": \"$after_id\","
    fi

    local children=$(cat "$json_file")

    curl -s -X PATCH "https://api.notion.com/v1/blocks/$page_id/children" \
        -H "$AUTH_HEADER" \
        -H "$VERSION_HEADER" \
        -H "$CONTENT_HEADER" \
        -d "{$after_param \"children\": $children}"
}

# 블록 삭제
# Usage: delete_block <block_id>
delete_block() {
    local block_id="$1"

    curl -s -X DELETE "https://api.notion.com/v1/blocks/$block_id" \
        -H "$AUTH_HEADER" \
        -H "$VERSION_HEADER"
}

# 페이지의 블록 목록 조회
# Usage: get_blocks <page_id>
get_blocks() {
    local page_id="$1"

    curl -s "https://api.notion.com/v1/blocks/$page_id/children?page_size=100" \
        -H "$AUTH_HEADER" \
        -H "$VERSION_HEADER"
}

# 페이지 제목 업데이트
# Usage: update_page_title <page_id> <title>
update_page_title() {
    local page_id="$1"
    local title="$2"

    curl -s -X PATCH "https://api.notion.com/v1/pages/$page_id" \
        -H "$AUTH_HEADER" \
        -H "$VERSION_HEADER" \
        -H "$CONTENT_HEADER" \
        -d "{\"properties\": {\"title\": {\"title\": [{\"text\": {\"content\": \"$title\"}}]}}}"
}

# 페이지 검색
# Usage: search_pages <query>
search_pages() {
    local query="$1"

    curl -s -X POST "https://api.notion.com/v1/search" \
        -H "$AUTH_HEADER" \
        -H "$VERSION_HEADER" \
        -H "$CONTENT_HEADER" \
        -d "{\"query\": \"$query\", \"filter\": {\"property\": \"object\", \"value\": \"page\"}}"
}

# 마크다운을 노션 블록으로 변환하여 추가
# Usage: add_markdown <page_id> <markdown_content>
add_markdown_content() {
    local page_id="$1"
    local content="$2"
    local after_id="$3"

    local children="["
    local first=true

    while IFS= read -r line || [ -n "$line" ]; do
        # 빈 줄 건너뛰기
        [ -z "$line" ] && continue

        local block_type="paragraph"
        local text="$line"

        # 마크다운 파싱
        if [[ "$line" =~ ^##[[:space:]](.+)$ ]]; then
            block_type="heading_2"
            text="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^###[[:space:]](.+)$ ]]; then
            block_type="heading_3"
            text="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^#[[:space:]](.+)$ ]]; then
            block_type="heading_1"
            text="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^-[[:space:]](.+)$ ]]; then
            block_type="bulleted_list_item"
            text="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^[0-9]+\.[[:space:]](.+)$ ]]; then
            block_type="numbered_list_item"
            text="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^\>[[:space:]](.+)$ ]]; then
            block_type="quote"
            text="${BASH_REMATCH[1]}"
        elif [[ "$line" == "---" ]]; then
            block_type="divider"
            text=""
        fi

        # JSON 이스케이프
        text=$(echo "$text" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')

        if [ "$first" = true ]; then
            first=false
        else
            children="$children,"
        fi

        if [ "$block_type" = "divider" ]; then
            children="$children{\"object\":\"block\",\"type\":\"divider\",\"divider\":{}}"
        else
            children="$children{\"object\":\"block\",\"type\":\"$block_type\",\"$block_type\":{\"rich_text\":[{\"type\":\"text\",\"text\":{\"content\":\"$text\"}}]}}"
        fi
    done <<< "$content"

    children="$children]"

    local after_param=""
    if [ -n "$after_id" ]; then
        after_param="\"after\": \"$after_id\","
    fi

    curl -s -X PATCH "https://api.notion.com/v1/blocks/$page_id/children" \
        -H "$AUTH_HEADER" \
        -H "$VERSION_HEADER" \
        -H "$CONTENT_HEADER" \
        -d "{$after_param \"children\": $children}"
}

# 메인 실행
case "$1" in
    add)
        add_block "$2" "$3" "$4" "$5"
        ;;
    add-blocks)
        add_blocks "$2" "$3" "$4"
        ;;
    add-markdown)
        add_markdown_content "$2" "$3" "$4"
        ;;
    delete)
        delete_block "$2"
        ;;
    get)
        get_blocks "$2"
        ;;
    title)
        update_page_title "$2" "$3"
        ;;
    search)
        search_pages "$2"
        ;;
    *)
        echo "Notion API Helper"
        echo ""
        echo "Usage:"
        echo "  $0 add <page_id> <block_type> <content> [after_block_id]"
        echo "  $0 add-blocks <page_id> <json_file> [after_block_id]"
        echo "  $0 add-markdown <page_id> <markdown_content> [after_block_id]"
        echo "  $0 delete <block_id>"
        echo "  $0 get <page_id>"
        echo "  $0 title <page_id> <title>"
        echo "  $0 search <query>"
        echo ""
        echo "Block types: heading_1, heading_2, heading_3, paragraph, bulleted_list_item, numbered_list_item, quote, callout, divider"
        ;;
esac
