#ifndef DUMP_SCOPE_H
#define DUMP_SCOPE_H

#ifdef Q_CC_GNU
#include <cxxabi.h>
#endif

#include <cppmodel/nameprettyprinter.h>
#include <cppmodel/overview.h>

#include <parser/Scope.h>
#include <parser/Symbol.h>
#include <parser/SymbolVisitor.h>

#include <QtCore/QIODevice>

class DumpScope : protected CPlusPlus::SymbolVisitor
{
  public:
    DumpScope(QIODevice *device)
      : m_depth(0)
      , m_device(device)
      , m_namePrinter(new CPlusPlus::CppModel::Overview())
    {}

    void operator()(CPlusPlus::Scope const &scope)
    {
      m_device->write("Namespace (Anonymous)\n");
      m_depth++;

      for (unsigned idx = 0; idx < scope.symbolCount(); ++idx)
      {
        accept(scope.symbolAt(idx));
      }

      m_depth--;
    }

  protected:
    virtual bool preVisit(CPlusPlus::Symbol *symbol)
    {
      const char *name;
      #ifdef Q_CC_GNU
      name = abi::__cxa_demangle(typeid(*symbol).name(), 0, 0, 0) + 11;
      #else
      name = typeid(*symbol).name();
      #endif

      QString data(m_depth, ' ');
      data += QString(name);
      data += " (" + m_namePrinter(symbol->name());
      data += ")\n";
      m_device->write(data.toUtf8());

      ++m_depth;
      return true;
    }

    virtual void postVisit(CPlusPlus::Symbol *)
    { --m_depth; }

  private:
    int                                    m_depth;
    QIODevice                             *m_device;
    CPlusPlus::CppModel::NamePrettyPrinter m_namePrinter;
};

#endif // DUMP_AST_H
