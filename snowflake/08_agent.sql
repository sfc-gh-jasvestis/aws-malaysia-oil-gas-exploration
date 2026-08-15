-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Upstream Exploration Analytics
-- ============================================================================
USE DATABASE OIL_GAS_EXPLORATION;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.EXPLORATION_INTELLIGENCE_AGENT
  COMMENT = 'Upstream Exploration Analytics AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'OIL_GAS_EXPLORATION.APP.EXPLORATION_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'OIL_GAS_EXPLORATION.SEARCH.SUBSURFACE_DOCS_SEARCH', TOOL_DESCRIPTION => 'Search documents for Oil & Gas — Upstream Exploration information')
  )
  SYSTEM_PROMPT = 'You are the Exploration Intelligence Agent for Malaysia''s upstream oil and gas operations across 8 offshore blocks in the Malay Basin and Sarawak Basin.';
