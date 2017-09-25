require 'minitest/autorun'
require 'objc_dependency_tree_generator'
require 'sourcekitten_dependencies_generator'

class SwiftAstDependenciesGeneratorTest < Minitest::Test
  def test_links_generation
    generator = DependencyTreeGenerator.new({})
    tree = generator.build_dependency_tree
    assert(tree.isEmpty?)
  end

  def test_simple_app_delegate
    generator = DependencyTreeGenerator.new(
      swift_ast_dump_file: './test/fixtures/swift-dump-ast/appdelegate.ast'
    )
    tree = generator.build_dependency_tree
    assert(tree.isRegistered?('AppDelegate'))
    assert_equal tree.type('AppDelegate'), DependencyItemType::CLASS
  end

  def test_all_classes
    generator = DependencyTreeGenerator.new(
      swift_ast_dump_file: './test/fixtures/swift-dump-ast/first-file.ast'
    )
    tree = generator.build_dependency_tree
    assert_equal tree.type('Protocol1Impl'), DependencyItemType::CLASS
    assert_equal tree.type('Protocol2Impl'), DependencyItemType::CLASS
    assert_equal tree.type('Class1'), DependencyItemType::CLASS
    assert_equal tree.type('ClassWithFunctions'), DependencyItemType::CLASS
  end

  def test_all_protocols
    generator = DependencyTreeGenerator.new(
      swift_ast_dump_file: './test/fixtures/swift-dump-ast/first-file.ast'
    )
    tree = generator.build_dependency_tree
    assert_equal tree.type('Protocol2'), DependencyItemType::PROTOCOL
    assert_equal tree.type('Protocol1'), DependencyItemType::PROTOCOL
  end

  def test_inheritance
    generator = DependencyTreeGenerator.new(
      swift_ast_dump_file: './test/fixtures/swift-dump-ast/first-file.ast'
    )
    tree = generator.build_dependency_tree
    assert tree.connected?('Protocol1Impl', 'Protocol1')
    assert_equal tree.link_type('Protocol1Impl', 'Protocol1'), DependencyLinkType::INHERITANCE
    assert_equal tree.link_type('Protocol2Impl', 'Protocol2'), DependencyLinkType::INHERITANCE

  end

  def test_variables_dependency
    generator = DependencyTreeGenerator.new(
      swift_ast_dump_file: './test/fixtures/swift-dump-ast/first-file.ast'
    )
    tree = generator.build_dependency_tree
    assert tree.connected?('Class1', 'Protocol1')
    assert tree.connected?('Class1', 'Protocol2')
    assert tree.connected?('Class1', 'Protocol1Impl')
    assert tree.connected?('Class1', 'Protocol2Impl')

    assert_equal tree.link_type('Class1', 'Protocol1'), DependencyLinkType::IVAR
    assert_equal tree.link_type('Class1', 'Protocol2'), DependencyLinkType::IVAR
    assert_equal tree.link_type('Class1', 'Protocol1Impl'), DependencyLinkType::CALL
    assert_equal tree.link_type('Class1', 'Protocol2Impl'), DependencyLinkType::CALL
  end

  def test_function_types_dependency
    generator = DependencyTreeGenerator.new(
      swift_ast_dump_file: './test/fixtures/swift-dump-ast/first-file.ast'
    )
    tree = generator.build_dependency_tree
    assert tree.connected?('ClassWithFunctions', 'Protocol1')
    assert_equal tree.link_type('ClassWithFunctions', 'Protocol1'), DependencyLinkType::PARAMETER

    assert tree.connected?('ClassWithFunctions', 'Protocol2')
    assert_equal tree.link_type('ClassWithFunctions', 'Protocol2'), DependencyLinkType::PARAMETER

    assert tree.connected?('ClassWithFunctions', 'Protocol2Impl')
    assert_equal tree.link_type('ClassWithFunctions', 'Protocol2Impl'), DependencyLinkType::CALL

  end  

  def test_generics_dependencies
    generator = DependencyTreeGenerator.new(
      swift_ast_dump_file: './test/fixtures/swift-dump-ast/second-file.ast'
      )
    tree = generator.build_dependency_tree

    assert(tree.isRegistered?('ProtocolForGeneric'))
    assert(tree.isRegistered?('ProtocolForGeneric2'))

    assert_nil tree.type('<A : ProtocolForGeneric>'), "Dependency should resolve generics and not take them as declaration"
    assert !tree.isRegistered?('<A : ProtocolForGeneric>'), "Dependency should resolve generics and not take them as declaration"

    assert tree.connected?('GenericClass', 'ProtocolForGeneric')
    assert tree.connected?('GenericClass2', 'ProtocolForGeneric')
    assert tree.connected?('GenericClass2', 'ProtocolForGeneric2')

    assert tree.connected?('GenericClass3', 'ProtocolForGeneric')
    assert tree.connected?('GenericClass3', 'ProtocolForGeneric2')

    assert tree.connected?('GenericClassWithProp', 'ProtocolForGeneric')
    
  end  

  def test_generics_usages_should_not_be_registered
    generator = DependencyTreeGenerator.new(
      swift_ast_dump_file: './test/fixtures/swift-dump-ast/second-file.ast'
      )
    tree = generator.build_dependency_tree

    assert(tree.isRegistered?('ProtocolForGeneric'))
    assert(tree.isRegistered?('ProtocolForGeneric2'))
    assert(!tree.isRegistered?('E'))

    assert tree.connected?('GenericClassWithProp', 'ProtocolForGeneric')
    assert !tree.connected?('GenericClassWithProp', 'E')

    assert(!tree.isRegistered?('GenericClassWithProp<E>'))

  end  


end
