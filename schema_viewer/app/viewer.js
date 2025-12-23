// Schema Viewer Application
class SchemaViewer {
  constructor() {
    this.schemas = [];
    this.currentFilter = "all";
    this.currentSearch = "";
    this.selectedSchema = null;

    this.init();
  }

  async init() {
    this.setupEventListeners();
    await this.loadSchemas();
  }

  setupEventListeners() {
    // Search input
    const searchInput = document.getElementById("searchInput");
    searchInput.addEventListener("input", (e) => {
      this.currentSearch = e.target.value.toLowerCase();
      this.filterSchemas();
    });

    // Filter buttons
    const filterButtons = document.querySelectorAll(".filter-btn");
    filterButtons.forEach((btn) => {
      btn.addEventListener("click", (e) => {
        filterButtons.forEach((b) => b.classList.remove("active"));
        e.target.classList.add("active");
        this.currentFilter = e.target.dataset.filter;
        this.filterSchemas();
      });
    });
  }

  async loadSchemas() {
    const listElement = document.getElementById("schemaList");
    listElement.innerHTML = '<div class="loading">Loading schemas...</div>';

    try {
      // Load the index file
      const indexResponse = await fetch("../schemas/_index.json");
      if (!indexResponse.ok) {
        throw new Error(
          "Index file not found. Please export schemas from Godot first."
        );
      }

      const index = await indexResponse.json();

      // Load all schemas
      const schemaPromises = [];

      // Load interfaces
      if (index.interfaces) {
        for (const interfaceName of index.interfaces) {
          schemaPromises.push(this.loadSchema(interfaceName, "interface"));
        }
      }

      // Load classes
      if (index.classes) {
        for (const className of index.classes) {
          schemaPromises.push(this.loadSchema(className, "class"));
        }
      }

      const schemas = await Promise.all(schemaPromises);
      this.schemas = schemas.filter((s) => s !== null);

      if (this.schemas.length === 0) {
        listElement.innerHTML =
          '<div class="empty-state">No schemas found. Export schemas from Godot using SchemaExporter.export_all_to_viewer()</div>';
      } else {
        this.renderSchemaList();
      }
    } catch (error) {
      console.error("Error loading schemas:", error);
      listElement.innerHTML = `<div class="error">⚠️ ${error.message}</div>`;
    }
  }

  async loadSchema(name, expectedType) {
    try {
      const response = await fetch(`../schemas/${name}.json`);
      if (!response.ok) return null;

      const data = await response.json();
      return {
        name: name,
        type: data.type || expectedType,
        data: data,
      };
    } catch (error) {
      console.error(`Error loading schema ${name}:`, error);
      return null;
    }
  }

  renderSchemaList() {
    const listElement = document.getElementById("schemaList");
    const countElement = document.getElementById("schemaCount");

    // Sort schemas by name
    this.schemas.sort((a, b) => a.name.localeCompare(b.name));

    listElement.innerHTML = "";

    this.schemas.forEach((schema) => {
      const item = document.createElement("div");
      item.className = "schema-item";
      item.dataset.type = schema.type;
      item.dataset.name = schema.name.toLowerCase();

      const icon = schema.type === "interface" ? "📋" : "🔷";

      item.innerHTML = `
                <span class="schema-icon">${icon}</span>
                <span class="schema-name">${schema.name}</span>
                <span class="schema-type ${schema.type}">${schema.type}</span>
            `;

      item.addEventListener("click", () => this.selectSchema(schema, item));
      listElement.appendChild(item);
    });

    countElement.textContent = this.schemas.length;
    this.filterSchemas();
  }

  filterSchemas() {
    const items = document.querySelectorAll(".schema-item");
    let visibleCount = 0;

    items.forEach((item) => {
      const matchesFilter =
        this.currentFilter === "all" ||
        item.dataset.type === this.currentFilter;
      const matchesSearch =
        this.currentSearch === "" ||
        item.dataset.name.includes(this.currentSearch);

      if (matchesFilter && matchesSearch) {
        item.classList.remove("hidden");
        visibleCount++;
      } else {
        item.classList.add("hidden");
      }
    });

    document.getElementById("schemaCount").textContent = visibleCount;
  }

  selectSchema(schema, itemElement) {
    // Update active state
    document.querySelectorAll(".schema-item").forEach((item) => {
      item.classList.remove("active");
    });
    itemElement.classList.add("active");

    this.selectedSchema = schema;
    this.renderSchemaDetail(schema);
  }

  renderSchemaDetail(schema) {
    const detailElement = document.getElementById("schemaDetail");

    if (schema.type === "interface") {
      this.renderInterfaceDetail(schema, detailElement);
    } else if (schema.type === "class") {
      this.renderClassDetail(schema, detailElement);
    }
  }

  renderInterfaceDetail(schema, container) {
    const schemaInfo = schema.data.schema;
    const icon = "📋";

    let html = `
            <div class="schema-header">
                <div class="schema-title">
                    <span style="font-size: 2rem;">${icon}</span>
                    <h2>${schema.name}</h2>
                    <span class="schema-type interface">Interface</span>
                </div>
                ${
                  schemaInfo.description
                    ? `<p class="schema-description">${schemaInfo.description}</p>`
                    : ""
                }
                <div class="schema-meta">
                    <div class="meta-item">
                        <strong>Extendable:</strong> ${
                          schemaInfo.is_extendable ? "Yes" : "No"
                        }
                    </div>
                    <div class="meta-item">
                        <strong>Fields:</strong> ${
                          Object.keys(schemaInfo.fields || {}).length
                        }
                    </div>
                </div>
            </div>
        `;

    // Base Schema Fields
    if (
      schemaInfo.base_schema &&
      Object.keys(schemaInfo.base_schema).length > 0
    ) {
      html += `
                <div class="fields-section">
                    <h3 class="section-title">📌 Base Fields</h3>
                    ${this.renderFieldTable(
                      schemaInfo.fields,
                      schemaInfo.base_schema
                    )}
                </div>
            `;
    }

    // Extended Fields
    const extendedFields = this.getExtendedFields(
      schemaInfo.fields,
      schemaInfo.base_schema
    );
    if (Object.keys(extendedFields).length > 0) {
      html += `
                <div class="fields-section">
                    <h3 class="section-title">🔧 Extended Fields</h3>
                    ${this.renderFieldTable(extendedFields)}
                </div>
            `;
    }

    // All Fields (if no base/extended distinction)
    if (
      (!schemaInfo.base_schema ||
        Object.keys(schemaInfo.base_schema).length === 0) &&
      schemaInfo.fields &&
      Object.keys(schemaInfo.fields).length > 0
    ) {
      html += `
                <div class="fields-section">
                    <h3 class="section-title">📋 Fields</h3>
                    ${this.renderFieldTable(schemaInfo.fields)}
                </div>
            `;
    }

    container.innerHTML = html;
  }

  renderClassDetail(schema, container) {
    const classInfo = schema.data.schema;
    const icon = "🔷";

    let html = `
            <div class="schema-header">
                <div class="schema-title">
                    <span style="font-size: 2rem;">${icon}</span>
                    <h2>${schema.name}</h2>
                    <span class="schema-type class">Class</span>
                </div>
                ${
                  classInfo.description
                    ? `<p class="schema-description">${classInfo.description}</p>`
                    : ""
                }
                <div class="schema-meta">
                    ${
                      classInfo.extends
                        ? `<div class="meta-item"><strong>Extends:</strong> ${classInfo.extends}</div>`
                        : ""
                    }
                    <div class="meta-item">
                        <strong>Fields:</strong> ${
                          Object.keys(classInfo.fields || {}).length
                        }
                    </div>
                    <div class="meta-item">
                        <strong>Exports:</strong> ${
                          Object.keys(classInfo.exports || {}).length
                        }
                    </div>
                    <div class="meta-item">
                        <strong>Signals:</strong> ${
                          (classInfo.signals || []).length
                        }
                    </div>
                </div>
            </div>
        `;

    // Signals
    if (classInfo.signals && classInfo.signals.length > 0) {
      html += `
                <div class="fields-section">
                    <h3 class="section-title">📡 Signals</h3>
                    <ul style="list-style: none; padding: 0;">
                        ${classInfo.signals
                          .map(
                            (sig) => `
                            <li style="padding: 8px; background: var(--background); margin-bottom: 5px; border-radius: 4px;">
                                <code style="color: var(--warning);">${sig}</code>
                            </li>
                        `
                          )
                          .join("")}
                    </ul>
                </div>
            `;
    }

    // Exported Variables
    if (classInfo.exports && Object.keys(classInfo.exports).length > 0) {
      html += `
                <div class="fields-section">
                    <h3 class="section-title">🔧 Exported Variables</h3>
                    ${this.renderClassFieldTable(classInfo.exports, true)}
                </div>
            `;
    }

    // All Variables
    if (classInfo.fields && Object.keys(classInfo.fields).length > 0) {
      html += `
                <div class="fields-section">
                    <h3 class="section-title">📋 All Variables</h3>
                    ${this.renderClassFieldTable(classInfo.fields, false)}
                </div>
            `;
    }

    container.innerHTML = html;
  }

  renderFieldTable(fields, baseSchema = null) {
    if (!fields || Object.keys(fields).length === 0) {
      return '<p class="empty-state">No fields defined</p>';
    }

    let html = '<table class="field-table"><thead><tr>';
    html += "<th>Field Name</th><th>Type</th><th>Attributes</th>";
    html += "</tr></thead><tbody>";

    for (const [fieldName, fieldInfo] of Object.entries(fields)) {
      // Skip if this is an extended field and we're showing base schema
      if (baseSchema && !baseSchema.hasOwnProperty(fieldName)) {
        continue;
      }

      const badges = [];
      if (fieldInfo.is_nullable)
        badges.push('<span class="field-badge nullable">Nullable</span>');
      if (fieldInfo.is_array)
        badges.push('<span class="field-badge array">Array</span>');
      if (fieldInfo.is_base_field)
        badges.push('<span class="field-badge base">Base</span>');

      html += `
                <tr>
                    <td class="field-name">${fieldName}</td>
                    <td class="field-type">${this.escapeHtml(
                      fieldInfo.type
                    )}</td>
                    <td>${badges.join(" ") || "-"}</td>
                </tr>
            `;
    }

    html += "</tbody></table>";
    return html;
  }

  renderClassFieldTable(fields, showExportOnly) {
    if (!fields || Object.keys(fields).length === 0) {
      return '<p class="empty-state">No fields defined</p>';
    }

    let html = '<table class="field-table"><thead><tr>';
    html += "<th>Variable Name</th><th>Type</th><th>Attributes</th>";
    html += "</tr></thead><tbody>";

    for (const [fieldName, fieldInfo] of Object.entries(fields)) {
      const badges = [];
      if (fieldInfo.is_export)
        badges.push('<span class="field-badge export">Export</span>');

      html += `
                <tr>
                    <td class="field-name">${fieldName}</td>
                    <td class="field-type">${this.escapeHtml(
                      fieldInfo.type
                    )}</td>
                    <td>${badges.join(" ") || "-"}</td>
                </tr>
            `;
    }

    html += "</tbody></table>";
    return html;
  }

  getExtendedFields(allFields, baseSchema) {
    if (!baseSchema) return {};

    const extended = {};
    for (const [fieldName, fieldInfo] of Object.entries(allFields)) {
      if (!baseSchema.hasOwnProperty(fieldName)) {
        extended[fieldName] = fieldInfo;
      }
    }
    return extended;
  }

  escapeHtml(text) {
    const map = {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#039;",
    };
    return text.replace(/[&<>"']/g, (m) => map[m]);
  }
}

// Initialize the viewer when the page loads
document.addEventListener("DOMContentLoaded", () => {
  new SchemaViewer();
});
