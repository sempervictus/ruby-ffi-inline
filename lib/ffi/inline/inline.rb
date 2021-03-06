#--
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'ffi/inline/error'

module FFI

module Inline
	def self.directory
		if ENV['FFI_INLINER_PATH'] && !ENV['FFI_INLINER_PATH'].empty?
			@directory = ENV['FFI_INLINER_PATH']
		else
			require 'tmpdir'
			@directory ||= File.expand_path(File.join(Dir.tmpdir, ".ffi-inline-#{Process.uid}"))
		end

		if File.exists?(@directory) && !File.directory?(@directory)
			raise 'the FFI_INLINER_PATH exists and is not a directory'
		end

		if !File.exists?(@directory)
			FileUtils.mkdir(@directory)
		end

		@directory
	end

	def inline (*args, &block)
		if self.class == Class
			instance_inline(*args, &block)
		else
			singleton_inline(*args, &block)
		end
	end

	def singleton_inline (*args)
		options = args.last.is_a?(Hash) ? args.pop : {}

		language, code = if args.length == 2
			args
		else
			block_given? ? [args.shift || :c, ''] : [:c, args.shift || '']
		end

		builder = Builder[language].new(code, options)
		yield builder if block_given?
		mod = builder.build

		builder.symbols.each {|sym|
			define_singleton_method sym, &mod.method(sym)
		}
	end

	def instance_inline (*args)
		options = args.last.is_a?(Hash) ? args.pop : {}

		language, code = if args.length == 2
			args
		else
			block_given? ? [args.shift || :c, ''] : [:c, args.shift || '']
		end

		builder = Builder[language].new(code, options)
		yield builder if block_given?
		mod = builder.build

		builder.symbols.each {|sym|
			define_method sym, &mod.method(sym)
		}
	end
end

end

require 'ffi/inline/compilers'
require 'ffi/inline/builders'
