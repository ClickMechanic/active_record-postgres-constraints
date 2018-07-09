# frozen_string_literal: true
module ActiveRecord
  module Postgres
    module Constraints
      module SchemaDumper

        if ActiveRecord::SchemaDumper.private_instance_methods(false).include?(:indexes_in_create)
          # Rails >= 5.0
          def indexes_in_create(table, stream)
            super
            constraints(table, stream)
          end

          private

          def build_constraint_statement(_, name, conditions)
            "    t.check_constraint :#{name}, #{conditions.inspect}"
          end

          def add_constraints_to_stream(stream, constraint_statements)
            stream.puts constraint_statements.sort.join("\n")
          end
        else
          # Rails < 5.0 does not have hook for table creation so fall back to
          # adding constraints after table creation.
          def indexes(table, stream)
            super
            constraints(table, stream)
          end

          private

          def build_constraint_statement(table, name, conditions)
            statement_parts = [
                "add_check_constraint #{remove_prefix_and_suffix(table).inspect}",
                name.inspect,
                conditions.inspect
            ]
            "  #{statement_parts.join(', ')}"
          end

          def add_constraints_to_stream(stream, constraint_statements)
            stream.puts constraint_statements.sort.join("\n")
            stream.puts
          end
        end

        def constraints(table, stream)
          constraints = @connection.constraints(table)
          return unless constraints.any?
          constraint_statements = constraints.map do |constraint|
            name = constraint['conname']
            conditions = constraint['consrc']
            build_constraint_statement(table, name, conditions)
          end
          add_constraints_to_stream(stream, constraint_statements)
        end

      end
    end
  end
end
