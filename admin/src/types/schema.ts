export interface ColumnInfo {
  column_name: string
  data_type: string
  udt_name: string
  is_nullable: 'YES' | 'NO'
  column_default: string | null
  character_maximum_length: number | null
  is_primary_key: boolean
  is_foreign_key: boolean
  foreign_table: string | null
  foreign_column: string | null
  enum_values: string[] | null
}

export interface TableInfo {
  table_name: string
  columns: ColumnInfo[]
  row_count: number
}

export interface SchemaMap {
  tables: TableInfo[]
}

export type FieldType =
  | 'text'
  | 'number'
  | 'boolean'
  | 'datetime'
  | 'json'
  | 'enum'
  | 'uuid'
  | 'select'

export function mapColumnToFieldType(col: ColumnInfo): FieldType {
  const { data_type, udt_name } = col

  if (udt_name === 'uuid') return 'uuid'
  if (udt_name === 'bool') return 'boolean'
  if (udt_name === 'jsonb' || udt_name === 'json') return 'json'
  if (data_type === 'USER-DEFINED') return 'enum'
  if (['timestamp', 'timestamptz', 'date'].some(t => udt_name.includes(t))) return 'datetime'
  if (['int2', 'int4', 'int8', 'float4', 'float8', 'numeric'].includes(udt_name)) return 'number'
  return 'text'
}
