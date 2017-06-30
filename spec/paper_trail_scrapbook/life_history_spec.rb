require 'spec_helper'

module PaperTrailScrapbook
  ::RSpec.describe LifeHistory do
    before do
      PaperTrailScrapbook.config.whodunnit_class = Person

      p = Person.new(name: 'The Tim Man')
      p.save!

      PaperTrail.whodunnit = p.id
    end

    let(:book) do
      b = Book.new(title: 'How the Grinch stole Xmas')
      b.save!
      b
    end

    let(:author) do
      p = Person.new(name: 'Dr. Seuss')
      p.save!
      p
    end
    
    let(:target) do
      a = Authorship.new(book: book, author: author)
      a.save!
      a
    end

    let(:object) { described_class.new(target) }
    let(:subject) { object.story }

    describe '#story' do
      it 'provides a whole story' do
        expect(subject).to match(/The Tim Man/)

        expect(subject).to match(/How the Grinch stole Xmas\[/)
        expect(subject).to match(/Dr. Seuss\[/)
      end

      it 'provides a whole story missing to_s content' do
        book.title = nil
        book.save!

        expect(subject).to match(/book: \[/)
      end

      it 'provides a whole story missing reference' do
        book.destroy

        expect(subject).to match(/book: \*not found\*\[/)
      end

      it 'provides a whole story missing reference' do
        target.book = nil
        target.save!

        expect(subject).to match(/How the Grinch stole Xmas\[1\] was \*removed\*/)
      end
    end
  end
end
