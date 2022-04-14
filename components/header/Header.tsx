import Link from "next/link";
import Network from "../network";
import TransactionsDisplay from "../TransactionsDisplay";

const PROD = process.env.NODE_ENV == "production";

export default function Header() {
  return (
    <header className="flex h-16 items-center justify-center">
      <Link href="/">
        <a id="logo">
          <span>Ubiquity Dollar</span>
        </a>
      </Link>
      <TransactionsDisplay />
    </header>
  );
}
