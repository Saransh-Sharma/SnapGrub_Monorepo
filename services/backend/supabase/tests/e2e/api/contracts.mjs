import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import Ajv2020 from "ajv/dist/2020.js";
import addFormats from "ajv-formats";
import YAML from "yaml";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../../../../../..");
const openApiPath = path.join(repoRoot, "packages/api-contracts/openapi.yaml");

const openApi = YAML.parse(fs.readFileSync(openApiPath, "utf8"));
const ajv = new Ajv2020({
  allErrors: true,
  strict: false,
  validateFormats: true,
});
addFormats(ajv);

const validators = new Map();

export function assertResponseMatchesContract(operationId, status, body) {
  const validator = validatorFor(operationId, String(status));
  if (!validator) {
    throw new Error(`No OpenAPI response schema found for ${operationId} ${status}`);
  }
  const valid = validator(body);
  assert.equal(
    valid,
    true,
    `${operationId} ${status} did not match OpenAPI: ${ajv.errorsText(validator.errors, { separator: "\n" })}`,
  );
}

function validatorFor(operationId, status) {
  const key = `${operationId}:${status}`;
  if (validators.has(key)) return validators.get(key);

  const operation = findOperation(operationId);
  const response = operation?.responses?.[status];
  const schema = response?.content?.["application/json"]?.schema;
  if (!schema) return null;

  const resolved = resolveRefs(schema);
  const validator = ajv.compile(resolved);
  validators.set(key, validator);
  return validator;
}

function findOperation(operationId) {
  for (const pathItem of Object.values(openApi.paths ?? {})) {
    for (const operation of Object.values(pathItem ?? {})) {
      if (operation?.operationId === operationId) return operation;
    }
  }
  return null;
}

function resolveRefs(value, seen = new Set()) {
  if (Array.isArray(value)) return value.map((item) => resolveRefs(item, seen));
  if (!value || typeof value !== "object") return value;

  if (typeof value.$ref === "string") {
    if (seen.has(value.$ref)) return {};
    seen.add(value.$ref);
    const resolved = lookupRef(value.$ref);
    const siblings = { ...value };
    delete siblings.$ref;
    return {
      ...resolveRefs(resolved, seen),
      ...resolveRefs(siblings, seen),
    };
  }

  return Object.fromEntries(
    Object.entries(value).map(([entryKey, entryValue]) => [entryKey, resolveRefs(entryValue, new Set(seen))]),
  );
}

function lookupRef(ref) {
  if (!ref.startsWith("#/")) throw new Error(`Only local OpenAPI refs are supported in tests: ${ref}`);
  return ref
    .slice(2)
    .split("/")
    .reduce((current, part) => current?.[part.replaceAll("~1", "/").replaceAll("~0", "~")], openApi);
}
