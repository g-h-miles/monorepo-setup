import './styles.css'

import { SelectDemo } from '@repo_name/ui/components/styled'
import { CounterButton } from '@repo_name/ui/counter-button'
import { Link } from '@repo_name/ui/link'

function App() {
  return (
    <div className="container">
      <h1 className="title">
        Admin <br />
        <span>Kitchen Sink</span>
      </h1>
      <CounterButton />
      <SelectDemo />
      <p className="description">
        Built With{' '}
        <Link href="https://turbo.build/repo" newTab>
          Turborepo
        </Link>
        {' & '}
        <Link href="https://vitejs.dev/" newTab>
          Vite
        </Link>
      </p>
    </div>
  )
}

export default App
