require 'active_support/concern'

module Brightcontent
  module BaseControllerExt
    module Pagination
      extend ActiveSupport::Concern

      included do
        helper_method :items_per_page
        helper_method :current_page
        helper_method :page_sizes
        helper_method :corrected_page
      end

      module ClassMethods
        def per_page_count
          @page_size = page_sizes.min
        end

        def per_page(number)
          @page_sizes = [number]
        end

        def page_size_options(sizes)
          return unless sizes.is_a? Array
          @page_sizes = sizes
        end

        def page_sizes
          @page_sizes ||= [30]
        end
      end

      private

      def items_per_page
        per_page = params[:per_page].try(:to_i)
        @items_per_page =
          if per_page && page_sizes.include?(per_page)
            per_page.to_i
          else
            self.class.per_page_count
          end
      end

      def current_page
        params[:page].try(:to_i) || 1
      end

      def corrected_page(size)
        (current_page - 1) * items_per_page / size + 1
      end

      def page_sizes
        self.class.page_sizes
      end

      def end_of_association_chain
        if action_name == "index" && items_per_page > 0
          super.paginate(page: params[:page], per_page: items_per_page)
        else
          super
        end
      end
    end
  end
end
