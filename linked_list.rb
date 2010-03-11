# Linked list implementation Copyright 2008 Aaron Patterson and Andrew Smith.

module PlasticPig
  module LinkedList
    include Enumerable

    attr_writer :previous
    attr_writer :next

    def next n = nil
      @next ||= nil
      return @next unless n
      list = []
      current_node = self
      n.times {
        current_node = current_node.next
        list << current_node
      }
      list
    end

    def previous n = nil
      @previous ||= nil
      return @previous unless n
      list = []
      current_node = self
      n.times {
        current_node = current_node.previous
        list << current_node
      }
      list.reverse
    end

    def ago n
      node = self
      n.times {
        node = node.previous
        return nil unless node
      }
      node
    end

    def ahead n
      node = self
      n.times {
        node = node.next
        return nil unless node
      }
      node
    end

    def << next_node
      next_node.previous = self
      self.next = next_node
      next_node
    end

    def slice!(start, length)
      head = ahead(start)
      head.previous = nil
      tail = head
      (length - 1).times { tail = tail.next }
      tail.next = nil
      head
    end

    def first
      current_node = self
      loop {
        return current_node unless current_node.previous
        current_node = current_node.previous
      }
    end

    def last
      current_node = self
      loop {
        return current_node unless current_node.next
        current_node = current_node.next
      }
    end

    def each &block
      current = self
      begin
        block.call(current)
      end while(current = current.next)
    end

    def length
      i = 0
      first.each { |n| i += 1 }
      i
    end
  end
end
